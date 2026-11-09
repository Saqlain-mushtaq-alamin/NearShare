import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:disk_space_plus/disk_space_plus.dart';

import '../../../core/utils/is_test_env.dart';

class FileStorageService {
  static const int maxFileNameLength = 200;
  static const Set<String> _reservedWindowsNames = <String>{
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

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
    sanitized = sanitized.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), '_');
    sanitized = sanitized.replaceFirst(RegExp(r'[. ]+$'), '');
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      sanitized = 'downloaded_file';
    }

    final String stem = p.basenameWithoutExtension(sanitized);
    if (_reservedWindowsNames.contains(stem.toUpperCase())) {
      sanitized = '_$sanitized';
    }
    return _truncateFileName(sanitized, maxFileNameLength);
  }

  String _truncateFileName(String name, int maxLength) {
    if (name.length <= maxLength) {
      return name;
    }
    String extension = p.extension(name);
    if (extension.length > 32) {
      extension = '';
    }
    final String stem = extension.isEmpty
        ? name
        : name.substring(0, name.length - extension.length);
    final int available = maxLength - extension.length;
    if (available <= 0) {
      return _safeSubstring(name, maxLength);
    }
    return '${_safeSubstring(stem, available)}$extension';
  }

  String _safeSubstring(String value, int end) {
    int safeEnd = end.clamp(0, value.length);
    if (safeEnd > 0 &&
        safeEnd < value.length &&
        _isHighSurrogate(value.codeUnitAt(safeEnd - 1))) {
      safeEnd--;
    }
    return value.substring(0, safeEnd);
  }

  bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  /// Resolves the root NearShare directory used for derived folders such as
  /// [getTempDirectory].
  Future<String> _nearShareRootDirectory() async {
    if (kIsWeb) {
      return '/downloads';
    }

    try {
      Directory baseDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        baseDir = extDir ?? await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final nearShareDir = Directory(p.join(baseDir.path, 'NearShare'));
      if (!await nearShareDir.exists()) {
        await nearShareDir.create(recursive: true);
      }
      return nearShareDir.path;
    } catch (e) {
      final temp = await getTemporaryDirectory();
      final fallback = Directory(p.join(temp.path, 'NearShare'));
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback.path;
    }
  }

  Future<String> _ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Resolves the default download/storage directory for NearShare.
  Future<String> getDownloadDirectory() async {
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      return _ensureDirectory(_customDownloadPath!);
    }

    if (kIsWeb) {
      return '/downloads';
    }

    final root = await _nearShareRootDirectory();
    return _ensureDirectory(p.join(root, 'Received'));
  }

  /// Resolves the scratch directory where partial chunk data is staged before
  /// a file is assembled into its final destination.
  Future<String> getTempDirectory() async {
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      return _ensureDirectory(p.join(_customDownloadPath!, 'Temp'));
    }

    if (kIsWeb) {
      return '/downloads/Temp';
    }

    final root = await _nearShareRootDirectory();
    return _ensureDirectory(p.join(root, 'Temp'));
  }

  /// Directory holding the received chunks of a single file.
  Future<Directory> chunkDirectoryFor(String transferId, int fileIndex) async {
    final temp = await getTempDirectory();
    final dir = Directory(p.join(temp, _safeSegment(transferId), '$fileIndex'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Absolute path of a single received chunk file.
  Future<File> chunkFileFor(
    String transferId,
    int fileIndex,
    int chunkIndex,
  ) async {
    final dir = await chunkDirectoryFor(transferId, fileIndex);
    return File(p.join(dir.path, '$chunkIndex.chunk'));
  }

  /// Deletes all staged chunk data for a transfer (both sides).
  Future<void> deleteTempDataFor(String transferId) async {
    if (transferId.isEmpty) return;
    try {
      final temp = Directory(await getTempDirectory());
      final target = Directory(p.join(temp.path, _safeSegment(transferId)));
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
    } catch (e) {
      debugPrint(
        '[FileStorageService] Failed to delete temp data for $transferId: $e',
      );
    }
  }

  /// Deletes the staged chunks of a single file inside a transfer.
  Future<void> deleteFileTempDataFor(String transferId, int fileIndex) async {
    if (transferId.isEmpty) return;
    try {
      final temp = Directory(await getTempDirectory());
      final target = Directory(
        p.join(temp.path, _safeSegment(transferId), '$fileIndex'),
      );
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
    } catch (e) {
      debugPrint(
        '[FileStorageService] Failed to delete temp data for '
        '$transferId/$fileIndex: $e',
      );
    }
  }

  String _safeSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'unknown' : sanitized;
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
      final String candidate = _truncateFileName(
        '$nameWithoutExt ($counter)$ext',
        maxFileNameLength,
      );
      targetPath = p.join(downloadDir, candidate);
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

  /// Returns free bytes on the download volume, or null when unavailable.
  Future<int?> getAvailableBytes() async {
    if (kIsWeb || isRunningUnderTest) {
      return null;
    }
    try {
      final String directory = await getDownloadDirectory();
      final double? freeMegabytes =
          await DiskSpacePlus().getFreeDiskSpaceForPath(directory);
      if (freeMegabytes == null || freeMegabytes.isNaN) {
        return null;
      }
      return (freeMegabytes * 1024 * 1024).floor();
    } catch (e) {
      debugPrint('[FileStorageService] Failed to read free disk space: $e');
      return null;
    }
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
      debugPrint(
        '[FileStorageService] Failed to delete incomplete file $filePath: $e',
      );
    }
  }
}
