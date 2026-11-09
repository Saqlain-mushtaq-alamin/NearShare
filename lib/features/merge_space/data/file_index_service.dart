import 'dart:io';

import 'package:crypto/crypto.dart';

import '../domain/merge_space_file.dart';
import 'merge_space_storage.dart';

/// Computes SHA-256 hashes and turns the Merge Space folder into index rows.
class FileIndexService {
  final MergeSpaceStorage storage;

  FileIndexService({MergeSpaceStorage? storage})
      : storage = storage ?? MergeSpaceStorage();

  /// SHA-256 of [file] contents as a lowercase hex string.
  Future<String> hashFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<String> hashPath(String path) => hashFile(File(path));

  Future<MergeSpaceFile> indexFile({
    required String relativePath,
    required String originDeviceId,
    String? baseHash,
  }) async {
    final normalized = MergeSpaceStorage.normalizeRelative(relativePath);
    final file = await storage.resolve(normalized);
    if (!await file.exists()) {
      throw FileSystemException('File is not inside the Merge Space', file.path);
    }
    final stat = await file.stat();
    return MergeSpaceFile(
      relativePath: normalized,
      hash: await hashFile(file),
      baseHash: baseHash,
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
      originDeviceId: originDeviceId,
    );
  }

  /// Scans the local folder and merges the result with [previous].
  ///
  /// Files that vanished keep a soft-delete tombstone so the deletion can be
  /// propagated instead of looking like a brand-new file on the other side.
  Future<List<MergeSpaceFile>> scan({
    required String localDeviceId,
    required List<MergeSpaceFile> previous,
  }) async {
    final root = await storage.ensureRoot();
    final previousByPath = {
      for (final file in previous) file.relativePath: file,
    };
    final indexed = <MergeSpaceFile>[];

    for (final file in await storage.listFiles()) {
      final relative = file.path
          .substring(root.length)
          .replaceAll('\\', '/')
          .replaceFirst(RegExp(r'^/+'), '');
      if (relative.isEmpty) continue;

      final stat = await file.stat();
      final handHash = await hashFile(file);
      final old = previousByPath[relative];
      final unchanged = old != null && !old.isDeleted && old.hash == handHash;

      indexed.add(
        MergeSpaceFile(
          relativePath: relative,
          hash: handHash,
          baseHash: unchanged ? old.baseHash : old?.baseHash,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
          originDeviceId:
              unchanged ? old.originDeviceId : localDeviceId,
        ),
      );
      previousByPath.remove(relative);
    }

    for (final missing in previousByPath.values) {
      if (missing.isDeleted) {
        indexed.add(missing);
      } else if (await storage.exists(missing.relativePath)) {
        indexed.add(missing);
      } else {
        indexed.add(
          missing.copyWith(
            isDeleted: true,
            originDeviceId: localDeviceId,
            modifiedAt: DateTime.now(),
          ),
        );
      }
    }

    indexed.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return indexed;
  }
}
