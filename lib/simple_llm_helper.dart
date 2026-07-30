import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

/// Simple helper class for LLM model operations without complex state management
class SimpleLLMHelper {
  /// Check if a model is available on the device
  static Future<bool> isModelAvailable() async {
    final modelPath = await findDownloadedModel();
    return modelPath != null;
  }

  /// Find the path to a downloaded model
  static Future<String?> findDownloadedModel() async {
    try {
      // Check download tasks first
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null && tasks.isNotEmpty) {
        for (final task in tasks) {
          if (task.status == DownloadTaskStatus.complete &&
              (task.filename?.contains('gemma') ?? false) &&
              (task.filename?.endsWith('.gguf') ?? false)) {
            final modelPath = '${task.savedDir}/${task.filename}';
            final file = File(modelPath);
            if (await file.exists()) {
              final fileSize = await file.length();
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
              debugPrint("✅ Found model file: $modelPath (${fileSizeMB}MB)");
              return modelPath;
            }
          }
        }
      }

      // Fallback: check documents directory
      final dir = await getApplicationDocumentsDirectory();
      final dirContents = await dir.list().toList();
      for (final item in dirContents) {
        if (item is File) {
          final fileName = item.path.split('/').last.split('\\').last;
          if (fileName.contains('gemma') && fileName.endsWith('.gguf')) {
            final fileSize = await item.length();
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            debugPrint("✅ Found model file: ${item.path} (${fileSizeMB}MB)");
            return item.path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error finding model: $e");
      return null;
    }
  }

  /// Get model file size in MB
  static Future<double?> getModelSize(String modelPath) async {
    try {
      final file = File(modelPath);
      if (await file.exists()) {
        final fileSize = await file.length();
        return fileSize / (1024 * 1024);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting model size: $e");
      return null;
    }
  }
}
