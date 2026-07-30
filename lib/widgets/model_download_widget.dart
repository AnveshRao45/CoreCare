import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:upgrade/services/model_storage_service.dart';

@pragma('vm:entry-point')
class ModelDownloadWidget extends StatefulWidget {
  final VoidCallback? onModelAvailable;

  const ModelDownloadWidget({super.key, this.onModelAvailable});

  @override
  State<ModelDownloadWidget> createState() => _ModelDownloadWidgetState();
}

@pragma('vm:entry-point')
class _ModelDownloadWidgetState extends State<ModelDownloadWidget> {
  final ReceivePort _port = ReceivePort();

  String? _taskId;
  int _progress = 0;
  DownloadTaskStatus? _status;
  bool _isLLMAvailable = false;
  String? _modelFilePath;

  static const String _modelFileName = "gemma-2-2b-it-Q6_K.gguf";

  // Get the correct download directory
  Future<Directory> _getDownloadDirectory() async {
    // Use the same directory that flutter_downloader uses
    // On Android, this is typically the app's internal directory
    return await getApplicationDocumentsDirectory();
  }

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
    _checkLLMAvailability();
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
      print("🔹 Filename: ${task.filename}, SavedDir: ${task.savedDir}");
    }

    // Find the most recent model download task
    final modelTasks = tasks
        .where(
          (task) =>
              task.url.contains('gemma') ||
              (task.filename?.contains('gemma') ?? false),
        )
        .toList();

    if (modelTasks.isNotEmpty) {
      final task = modelTasks.last;
      setState(() {
        _taskId = task.taskId;
        _progress = task.progress;
        _status = task.status;
      });

      print(
        "📦 Restored model task -> id=$_taskId, progress=$_progress%, status=$_status",
      );
      print("📦 Task file: ${task.filename} in ${task.savedDir}");
    }
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

        // Check availability when download completes
        if (status == DownloadTaskStatus.complete) {
          _checkLLMAvailability();
        }
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> check() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null || tasks.isEmpty) return;

    final task = tasks.first;
    final fullPath = p.join(task.savedDir, task.filename ?? '');
    final file = File(fullPath);

    print('🔍 Checking file at: $fullPath');
    final exists = await file.exists();
    print('✅ File exists: $exists');

    if (exists) {
      final sizeBytes = await file.length();
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
      print('📏 File size: $sizeMB MB');
    }
  }

  // 🔹 Check if LLM model is available locally
  Future<void> _checkLLMAvailability() async {
    try {
      // Fast path: unified model locator (handles Windows paths + folder scan)
      final located = await ModelStorageService.findGgufModel();
      if (located != null) {
        setState(() {
          _isLLMAvailable = true;
          _modelFilePath = located;
        });
        widget.onModelAvailable?.call();
        return;
      }

      // First, check if we have any completed download tasks and use their path
      final tasks = await FlutterDownloader.loadTasks();
      String? actualDownloadPath;

      if (tasks != null) {
        final modelTasks = tasks
            .where(
              (task) =>
                  task.url.contains('gemma') ||
                  (task.filename?.contains('gemma') ?? false),
            )
            .toList();

        if (modelTasks.isNotEmpty) {
          print("🔍 Found ${modelTasks.length} model tasks");
          for (final task in modelTasks) {
            print(
              "🔍 Task: ${task.taskId}, Status: ${task.status}, File: ${task.filename}, Dir: ${task.savedDir}",
            );
          }

          final completedTask = modelTasks
              .where((task) => task.status == DownloadTaskStatus.complete)
              .lastOrNull;

          print("🔍 Completed task found: ${completedTask != null}");

          if (completedTask != null) {
            actualDownloadPath =
                '${completedTask.savedDir}/${completedTask.filename}';
            print(
              "🔍 Checking actual download path: ${actualDownloadPath} and ${completedTask}",
            );

            final modelFile = File(actualDownloadPath);
            final exists = await modelFile.exists();

            print("🔍 File exists check result: $exists");

            if (!exists) {
              // Check if the file exists with a different name in the same directory
              final savedDir = Directory(completedTask.savedDir!);
              if (await savedDir.exists()) {
                print("📁 Checking saved directory: ${completedTask.savedDir}");
                final dirContents = await savedDir.list().toList();
                print("📁 Saved directory contents:");
                for (final item in dirContents) {
                  if (item is File) {
                    final fileName = item.path.split('/').last.split('\\').last;
                    print("   📄 File: $fileName");

                    // Check if this might be our model file
                    if (fileName.contains('gemma') &&
                        fileName.endsWith('.gguf')) {
                      print(
                        "🎯 Found model file with different name: $fileName",
                      );
                      final fileSize = await item.length();
                      final fileSizeMB = (fileSize / (1024 * 1024))
                          .toStringAsFixed(1);
                      print(
                        "✅ LLM model found: ${item.path} (${fileSizeMB}MB)",
                      );

                      setState(() {
                        _isLLMAvailable = true;
                        _modelFilePath = item.path;
                      });

                      // Notify parent that model is available
                      if (widget.onModelAvailable != null) {
                        widget.onModelAvailable!();
                      }
                      return;
                    }
                  }
                }
              }
            } else {
              final fileSize = await modelFile.length();
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
              print(
                "✅ LLM model found at actual path: $actualDownloadPath (${fileSizeMB}MB)",
              );

              setState(() {
                _isLLMAvailable = true;
                _modelFilePath = actualDownloadPath;
              });

              // Notify parent that model is available
              if (widget.onModelAvailable != null) {
                widget.onModelAvailable!();
              }
              return;
            }
          }
        }
      }

      // Fallback: check in the expected download directory
      final dir = await _getDownloadDirectory();
      print("🔍 Fallback check in directory: ${dir.path}");

      // Check for the exact filename first
      File modelFile = File('${dir.path}/$_modelFileName');
      bool exists = await modelFile.exists();

      // if (!exists) {
      // If not found, list all files in the directory to see what's actually there
      final dirContents = await dir.list().toList();
      print("📁 Directory contents:");
      for (final item in dirContents) {
        if (item is File) {
          final fileName = item.path.split('/').last.split('\\').last;
          print("   📄 File: $fileName");

          // Check if this might be our model file (sometimes downloads have different names)
          if (fileName.contains('gemma') && fileName.endsWith('.gguf')) {
            modelFile = item;
            exists = true;
            print("🎯 Found potential model file: $fileName");
            break;
          }
        }
      }
      // }

      setState(() {
        _isLLMAvailable = exists;
        _modelFilePath = exists ? modelFile.path : null;
      });

      if (exists) {
        final fileSize = await modelFile.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        print("✅ LLM model found: ${modelFile.path} (${fileSizeMB}MB)");

        // Notify parent that model is available
        if (widget.onModelAvailable != null) {
          widget.onModelAvailable!();
        }
      } else {
        print("❌ LLM model not found in: ${dir.path}");
      }
    } catch (e) {
      print("⚠️ Error checking LLM availability: $e");
      setState(() {
        _isLLMAvailable = false;
        _modelFilePath = null;
      });
    }
  }

  // 🔹 Request a new download
  Future<void> _requestDownload() async {
    final dir = await _getDownloadDirectory();
    print("📥 Starting download to directory: ${dir.path}");
    print("📥 Expected filename: $_modelFileName");

    final taskId = await FlutterDownloader.enqueue(
      fileName: _modelFileName,
      url:
          "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q6_K.gguf",
      savedDir: dir.path,
      headers: {'auth': 'test_for_sql_encoding'},
      saveInPublicStorage: false,
      showNotification: true,
      openFileFromNotification: false,
    );

    print("📥 Download task created with ID: $taskId");

    setState(() {
      _taskId = taskId;
      _status = DownloadTaskStatus.running;
      _progress = 0;
      _isLLMAvailable = false; // Reset availability during download
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download,
                  color: Color(0xFFFF8A50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model Download',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Download required AI model for offline use',
                      style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: () {
                  check();
                },
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh availability check',
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF718096),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // LLM Availability Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isLLMAvailable
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isLLMAvailable
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isLLMAvailable ? Icons.check_circle : Icons.warning,
                  color: _isLLMAvailable ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLLMAvailable
                            ? 'LLM Model Available'
                            : 'LLM Model Required',
                        style: TextStyle(
                          color: _isLLMAvailable ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isLLMAvailable
                            ? 'Ready for offline AI processing'
                            : 'Download model to enable AI features',
                        style: TextStyle(
                          color: _isLLMAvailable ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Download Status and Progress Section
          if (_status != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor().withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_status == DownloadTaskStatus.running)
                    Text(
                      '$_progress%',
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Progress Bar
            if (_status == DownloadTaskStatus.running) ...[
              LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF8A50),
                ),
                minHeight: 6,
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Action Buttons
          Row(
            children: [
              if (_isLLMAvailable &&
                  (_status == null ||
                      _status == DownloadTaskStatus.complete)) ...[
                // Model is available - show ready state
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Model Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Re-download option
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestDownload,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Re-download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A50),
                      side: const BorderSide(color: Color(0xFFFF8A50)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else if (!_isLLMAvailable &&
                  (_status == null ||
                      _status == DownloadTaskStatus.failed ||
                      _status == DownloadTaskStatus.canceled)) ...[
                // Model not available - show download button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestDownload,
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Download AI Model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ] else if (_status == DownloadTaskStatus.running) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pauseDownload,
                    icon: const Icon(Icons.pause, size: 20),
                    label: const Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A50),
                      side: const BorderSide(color: Color(0xFFFF8A50)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelDownload,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else if (_status == DownloadTaskStatus.paused) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resumeDownload,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelDownload,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else if (_status == DownloadTaskStatus.complete &&
                  !_isLLMAvailable) ...[
                // Download shows complete but file is missing - offer to retry
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Download Incomplete',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      check();
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Retry Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case DownloadTaskStatus.running:
        return const Color(0xFFFF8A50);
      case DownloadTaskStatus.paused:
        return Colors.orange;
      case DownloadTaskStatus.complete:
        return _isLLMAvailable ? Colors.green : Colors.orange;
      case DownloadTaskStatus.failed:
        return Colors.red;
      case DownloadTaskStatus.canceled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case DownloadTaskStatus.running:
        return Icons.downloading;
      case DownloadTaskStatus.paused:
        return Icons.pause_circle;
      case DownloadTaskStatus.complete:
        return Icons.check_circle;
      case DownloadTaskStatus.failed:
        return Icons.error;
      case DownloadTaskStatus.canceled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case DownloadTaskStatus.running:
        return 'Downloading...';
      case DownloadTaskStatus.paused:
        return 'Download Paused';
      case DownloadTaskStatus.complete:
        return _isLLMAvailable
            ? 'Download Complete'
            : 'Download Incomplete - File Missing';
      case DownloadTaskStatus.failed:
        return 'Download Failed';
      case DownloadTaskStatus.canceled:
        return 'Download Canceled';
      default:
        return 'Ready to Download';
    }
  }
}
