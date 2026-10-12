import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  final String? _customDownloadPath;

  FileStorageService({String? customDownloadPath})
      : _customDownloadPath = customDownloadPath;

  /// Sanitizes a file name to avoid path traversal and illegal filesystem characters.
  String sanitizeFileName(String name) {
    var sanitized = p.basename(name).trim();
    if (sanitized.isEmpty) {
      sanitized = 'downloaded_file';
    }
    // Remove characters that are problematic on Windows and POSIX filesystems
    sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized;
  }

  /// Resolves the default download/storage directory for NearShare.
  Future<String> getDownloadDirectory() async {
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      final dir = Directory(_customDownloadPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }

    if (kIsWeb) {
      return '/downloads';
    }

    try {
      Directory baseDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        baseDir = extDir ?? await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS || Platform.isMacOS) {
        baseDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isLinux) {
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final nearShareDir = Directory(p.join(baseDir.path, 'NearShare', 'Received'));
      if (!await nearShareDir.exists()) {
        await nearShareDir.create(recursive: true);
      }
      return nearShareDir.path;
    } catch (e) {
      final temp = await getTemporaryDirectory();
      final fallback = Directory(p.join(temp.path, 'NearShare', 'Received'));
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback.path;
    }
  }

  /// Generates a non-conflicting unique file destination in the download directory.
  Future<File> prepareDestinationFile(String fileName) async {
    final sanitized = sanitizeFileName(fileName);
    final downloadDir = await getDownloadDirectory();

    final ext = p.extension(sanitized);
    final nameWithoutExt = p.basenameWithoutExtension(sanitized);

    var targetPath = p.join(downloadDir, sanitized);
    var targetFile = File(targetPath);
    var counter = 1;

    while (await targetFile.exists()) {
      targetPath = p.join(downloadDir, '$nameWithoutExt ($counter)$ext');
      targetFile = File(targetPath);
      counter++;
    }

    // Ensure parent folder exists
    final parent = targetFile.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    return targetFile;
  }

  /// Safely deletes a file if it exists (e.g. after cancellation or failure).
  Future<void> deleteIncompleteFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[FileStorageService] Failed to delete incomplete file $filePath: $e');
    }
  }
}
