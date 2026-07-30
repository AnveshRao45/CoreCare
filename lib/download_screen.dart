import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DownloadScreenState();
}

@pragma('vm:entry-point')
class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  final ReceivePort _port = ReceivePort();

  String? _taskId;
  int _progress = 0;
  DownloadTaskStatus? _status;

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await FlutterDownloader.loadTasks();

    if (tasks == null || tasks.isEmpty) {
      print("🟡 No tasks found in FlutterDownloader.");
      return;
    }

    print("✅ Loaded ${tasks.length} tasks from downloader DB:");
    for (final task in tasks) {
      print(
        "🔹 ID: ${task.taskId}, Status: ${task.status}, Progress: ${task.progress}%, URL: ${task.url}",
      );
    }

    // Assuming you handle only one task
    final task = tasks.last;

    setState(() {
      _taskId = task.taskId;
      _progress = task.progress;
      _status = task.status;
    });

    print(
      "📦 Restored task -> id=$_taskId, progress=$_progress%, status=$_status",
    );
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  // 🔹 Register the callback (background isolate -> UI)
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  // 🔹 Bind background isolate to main isolate
  void _bindBackgroundIsolate() {
    final success = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!success) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }

    _port.listen((dynamic data) {
      final id = data[0] as String;
      final status = DownloadTaskStatus.fromInt(data[1] as int);
      final progress = data[2] as int;

      if (_taskId == id) {
        setState(() {
          _status = status;
          _progress = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  // 🔹 Request a new download
  Future<void> _requestDownload() async {
    final dir = await getApplicationDocumentsDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url:
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      savedDir: dir.path,
      headers: {'auth': 'test_for_sql_encoding'},
      saveInPublicStorage: true,
      showNotification: true,
      // openFileFromNotification: true,
    );

    setState(() {
      _taskId = taskId;
      _status = DownloadTaskStatus.running;
      _progress = 0;
    });
  }

  // 🔹 Pause download
  Future<void> _pauseDownload() async {
    if (_taskId != null) {
      await FlutterDownloader.pause(taskId: _taskId!);
    }
  }

  // 🔹 Resume download
  Future<void> _resumeDownload() async {
    if (_taskId != null) {
      final newTaskId = await FlutterDownloader.resume(taskId: _taskId!);
      setState(() {
        _taskId = newTaskId;
        _status = DownloadTaskStatus.running;
      });
    }
  }

  // 🔹 Cancel download
  Future<void> _cancelDownload() async {
    if (_taskId != null) {
      await FlutterDownloader.cancel(taskId: _taskId!);
      setState(() {
        _taskId = null;
        _progress = 0;
        _status = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        _status == DownloadTaskStatus.running ||
        _status == DownloadTaskStatus.enqueued;
    final isPaused = _status == DownloadTaskStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloader Example'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 16),
              Text(
                'Progress: $_progress%',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: isDownloading ? null : _requestDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Start'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isPaused ? _resumeDownload : _pauseDownload,
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPaused ? 'Resume' : 'Pause'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _cancelDownload,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
