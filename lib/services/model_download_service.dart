import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

enum ButtonState { download, cancel, pause, resume, reset }

class ModelDownloadService {
  static final ModelDownloadService _instance =
      ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  final log = Logger('ModelDownloadService');

  ButtonState buttonState = ButtonState.download;
  TaskStatus? downloadTaskStatus;
  DownloadTask? backgroundDownloadTask;
  StreamController<TaskProgressUpdate> progressUpdateStream =
      StreamController.broadcast();

  // Add state change stream
  StreamController<ButtonState> _stateController = StreamController.broadcast();
  Stream<ButtonState> get stateStream => _stateController.stream;

  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  /// Initialize the download service
  Future<void> initialize() async {
    if (_isInitialized) {
      log.info('ModelDownloadService already initialized');
      return;
    }

    try {
      // Configure the FileDownloader
      await FileDownloader().configure(
        globalConfig: [(Config.requestTimeout, const Duration(seconds: 100))],
        androidConfig: [(Config.useCacheDir, Config.whenAble)],
        iOSConfig: [
          (Config.localize, {'Cancel': 'StopIt'}),
        ],
      );

      // Register callbacks and configure notifications
      FileDownloader()
          .registerCallbacks(
            taskNotificationTapCallback: myNotificationTapCallback,
          )
          .configureNotificationForGroup(
            FileDownloader.defaultGroup,
            running: const TaskNotification(
              'Download {filename}',
              'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining',
            ),
            complete: const TaskNotification(
              '{displayName} download {filename}',
              'Download complete',
            ),
            error: const TaskNotification(
              'Download {filename}',
              'Download failed',
            ),
            paused: const TaskNotification(
              'Download {filename}',
              'Paused with metadata {metadata}',
            ),
            canceled: const TaskNotification('Download {filename}', 'Canceled'),
            progressBar: true,
          );

      // Listen to updates and process
      FileDownloader().updates.listen((update) {
        switch (update) {
          case TaskStatusUpdate():
            if (update.task == backgroundDownloadTask) {
              final oldState = buttonState;
              buttonState = switch (update.status) {
                TaskStatus.running || TaskStatus.enqueued => ButtonState.pause,
                TaskStatus.paused => ButtonState.resume,
                _ => ButtonState.reset,
              };
              downloadTaskStatus = update.status;

              // Notify listeners if state changed
              if (oldState != buttonState) {
                _stateController.add(buttonState);
              }

              log.info(
                'Status update: ${update.status}, Button state: $buttonState',
              );
            }
          case TaskProgressUpdate():
            if (update.task == backgroundDownloadTask) {
              progressUpdateStream.add(update);
            }
        }
      });

      // Start the FileDownloader
      FileDownloader().start();

      // Check for existing downloads
      await _checkForExistingDownloads();

      _isInitialized = true;
      log.info('ModelDownloadService initialized successfully');
    } catch (e) {
      log.severe('Error initializing ModelDownloadService: $e');
      _isInitialized = true;
    }
  }

  /// Process button press based on current state
  Future<void> processButtonPress() async {
    switch (buttonState) {
      case ButtonState.download:
        // start download
        backgroundDownloadTask = DownloadTask(
          url:
              'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q6_K.gguf',
          filename: 'gemma-2-2b-it-Q6_K.gguf',
          directory: 'aimodels',
          baseDirectory: BaseDirectory.applicationDocuments,
          updates: Updates.statusAndProgress,
          retries: 3,
          allowPause: true,
          metaData: '<Gemma 2B Model>',
          displayName: 'Gemma 2B Model',
        );
        await FileDownloader().enqueue(backgroundDownloadTask!);
        break;

      case ButtonState.cancel:
        // cancel download
        if (backgroundDownloadTask != null) {
          await FileDownloader().cancelTasksWithIds([
            backgroundDownloadTask!.taskId,
          ]);
        }
        break;

      case ButtonState.reset:
        downloadTaskStatus = null;
        buttonState = ButtonState.download;
        _stateController.add(buttonState);
        break;

      case ButtonState.pause:
        if (backgroundDownloadTask != null) {
          await FileDownloader().pause(backgroundDownloadTask!);
        }
        break;

      case ButtonState.resume:
        if (backgroundDownloadTask != null) {
          await FileDownloader().resume(backgroundDownloadTask!);
        }
        break;
    }
  }

  /// Check for existing downloads when app restarts
  Future<void> _checkForExistingDownloads() async {
    try {
      final allTasks = await FileDownloader().allTasks();
      for (final task in allTasks) {
        if (task is DownloadTask &&
            task.filename == 'gemma-2-2b-it-Q6_K.gguf' &&
            task.directory == 'aimodels') {
          backgroundDownloadTask = task;
          log.info('Found existing download task: ${task.taskId}');

          // Update button state based on task status
          // We'll get the actual status from the next update
          buttonState = ButtonState.pause; // Assume it's running
          _stateController.add(buttonState);
          break;
        }
      }
    } catch (e) {
      log.warning('Error checking for existing downloads: $e');
    }
  }

  /// Process the user tapping on a notification by printing a message
  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    debugPrint(
      'Tapped notification $notificationType for taskId ${task.taskId}',
    );
  }

  /// Get button text based on current state
  String getButtonText() {
    const buttonTexts = ['Download', 'Cancel', 'Pause', 'Resume', 'Reset'];
    return buttonTexts[buttonState.index];
  }

  /// Reset download state
  void resetDownload() {
    backgroundDownloadTask = null;
    downloadTaskStatus = null;
    buttonState = ButtonState.download;
  }

  /// Dispose resources
  void dispose() {
    progressUpdateStream.close();
    _stateController.close();
    _isInitialized = false;
  }
}
