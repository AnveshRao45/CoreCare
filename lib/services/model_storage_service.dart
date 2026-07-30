import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ModelStorageService {
  static const String defaultModelFileName = 'gemma-2-2b-it-Q6_K.gguf';

  static Future<String?> findGgufModel() async {
    try {
      // 1. Completed FlutterDownloader tasks (most reliable after download)
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null) {
        for (final task in tasks.reversed) {
          if (task.status != DownloadTaskStatus.complete) continue;

          final filename = task.filename ?? '';
          final savedDir = task.savedDir;
          if (savedDir.isEmpty) continue;

          final candidate = p.join(savedDir, filename);
          if (await _isValidGguf(candidate)) {
            debugPrint('[ModelStorage] Found via downloader task: $candidate');
            return candidate;
          }

          // Sometimes the saved filename differs — scan the download folder.
          final dir = Directory(savedDir);
          if (await dir.exists()) {
            for (final entity in await dir.list().toList()) {
              if (entity is File && entity.path.toLowerCase().endsWith('.gguf')) {
                if (await _isValidGguf(entity.path)) {
                  debugPrint('[ModelStorage] Found in savedDir: ${entity.path}');
                  return entity.path;
                }
              }
            }
          }
        }
      }

      // 2. Application documents directory (fallback)
      final docs = await getApplicationDocumentsDirectory();
      final direct = p.join(docs.path, defaultModelFileName);
      if (await _isValidGguf(direct)) {
        debugPrint('[ModelStorage] Found in documents: $direct');
        return direct;
      }

      if (await docs.exists()) {
        for (final entity in await docs.list().toList()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.gguf')) {
            if (await _isValidGguf(entity.path)) {
              debugPrint('[ModelStorage] Found gguf in documents: ${entity.path}');
              return entity.path;
            }
          }
        }
      }

      debugPrint('[ModelStorage] No GGUF model found on device');
      return null;
    } catch (e, st) {
      debugPrint('[ModelStorage] Error searching for model: $e\n$st');
      return null;
    }
  }

  static Future<bool> _isValidGguf(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    // Ignore tiny/corrupt files (< 10 MB)
    return size > 10 * 1024 * 1024;
  }
}
