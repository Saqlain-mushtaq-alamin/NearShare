import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the on-disk Merge Space folder and safe relative-path resolution.
class MergeSpaceStorage {
  static const String folderName = 'Merge Space';

  final String? _customRootPath;
  String? _resolvedRoot;

  MergeSpaceStorage({String? customRootPath}) : _customRootPath = customRootPath;

  Future<String> ensureRoot() async {
    final existing = _resolvedRoot;
    if (existing != null) return existing;

    final root = _customRootPath != null && _customRootPath!.isNotEmpty
        ? _customRootPath!
        : await _defaultRoot();
    final dir = Directory(root);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _resolvedRoot = dir.path;
    return dir.path;
  }

  Future<String> _defaultRoot() async {
    Directory base;
    try {
      if (Platform.isAndroid) {
        base = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        base = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      base = await getTemporaryDirectory();
    }
    return p.join(base.path, 'NearShare', folderName);
  }

  /// Normalizes a path to the `/`-separated form stored in the index.
  ///
  /// Throws when the path escapes the Merge Space root.
  static String normalizeRelative(String relativePath) {
    final trimmed = relativePath.trim().replaceAll('\\', '/');
    final withoutLeading = trimmed.replaceFirst(RegExp(r'^/+'), '');
    final segments = withoutLeading.split('/');
    if (withoutLeading.isEmpty ||
        segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Must be a safe path inside the Merge Space',
      );
    }
    return segments.join('/');
  }

  static bool isSafeRelativePath(String relativePath) {
    try {
      normalizeRelative(relativePath);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<File> resolve(String relativePath) async {
    final root = await ensureRoot();
    final normalized = normalizeRelative(relativePath);
    final file = File(p.joinAll([root, ...normalized.split('/')]));
    final rootPath = p.normalize(root);
    final filePath = p.normalize(file.path);
    if (!p.isWithin(rootPath, filePath)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Path escapes the Merge Space root',
      );
    }
    return file;
  }

  Future<String> relativePathOf(File file) async {
    final root = await ensureRoot();
    return p
        .relative(file.path, from: root)
        .replaceAll('\\', '/');
  }

  Future<File> writeBytes(String relativePath, List<int> bytes) async {
    final target = await resolve(relativePath);
    await target.parent.create(recursive: true);
    final staging = File('${target.path}.merge-tmp');
    await staging.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await staging.rename(target.path);
    return target;
  }

  Future<List<int>> readBytes(String relativePath) async {
    final file = await resolve(relativePath);
    if (!await file.exists()) {
      throw FileSystemException('Merge Space file not found', file.path);
    }
    return file.readAsBytes();
  }

  Future<bool> exists(String relativePath) async {
    final file = await resolve(relativePath);
    return file.exists();
  }

  Future<void> delete(String relativePath) async {
    final file = await resolve(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> rename(String fromRelative, String toRelative) async {
    final source = await resolve(fromRelative);
    if (!await source.exists()) return;
    final target = await resolve(toRelative);
    await target.parent.create(recursive: true);
    if (await target.exists()) {
      await target.delete();
    }
    await source.rename(target.path);
  }

  Future<List<File>> listFiles() async {
    final root = await ensureRoot();
    final dir = Directory(root);
    if (!await dir.exists()) return const [];
    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.endsWith('.merge-tmp')) continue;
        if (name.startsWith('.')) continue;
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }
}
