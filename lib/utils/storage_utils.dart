import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageUtils {
  static Future<int> getAvailableSpace() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (Platform.isAndroid) {
        final stat = await Process.run('df', [directory.path]);
        final output = stat.stdout.toString();
        final lines = output.split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length > 3) {
            return int.tryParse(parts[3]) ?? 0; // Available space in KB
          }
        }
      } else if (Platform.isIOS) {
        // iOS doesn't provide easy access to available space
        // Return a large number as fallback
        return 100 * 1024 * 1024; // 100GB
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting available space: $e');
      return 0;
    }
  }

  static Future<bool> hasEnoughSpace(String filePath, int requiredBytes) async {
    try {
      final availableBytes = await getAvailableSpace();
      return availableBytes * 1024 >= requiredBytes; // Convert KB to bytes
    } catch (e) {
      debugPrint('Error checking space: $e');
      return false;
    }
  }

  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  static String calculateSpeed(int bytesDownloaded, int startTime) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    if (elapsed == 0) return '0 B/s';

    final speedBps = (bytesDownloaded * 1000) ~/ elapsed;
    return '${formatBytes(speedBps)}/s';
  }

  static String calculateETA(int bytesRemaining, int speedBps) {
    if (speedBps == 0) return 'Unknown';

    final etaSeconds = bytesRemaining ~/ speedBps;
    if (etaSeconds < 60) {
      return '${etaSeconds}s';
    } else {
      final minutes = etaSeconds ~/ 60;
      final seconds = etaSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
  }
}
