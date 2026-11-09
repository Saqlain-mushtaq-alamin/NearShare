import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/sync_engine.dart';

MergeSpaceFile file(
  String path, {
  String? hash,
  String? baseHash,
  bool deleted = false,
  int size = 10,
}) {
  return MergeSpaceFile(
    relativePath: path,
    hash: hash ?? 'hash-$path',
    baseHash: baseHash,
    sizeBytes: size,
    modifiedAt: DateTime(2026, 1, 1),
    isDeleted: deleted,
    originDeviceId: 'device-a',
  );
}

void main() {
  const engine = SyncEngine();

  SyncPlan plan({
    List<MergeSpaceFile> local = const [],
    List<MergeSpaceFile> remote = const [],
  }) {
    return engine.buildPlan(
      localDeviceId: 'device-a',
      peerDeviceId: 'device-b',
      localFiles: local,
      remoteFiles: remote,
    );
  }

  group('SyncEngine', () {
    test('downloads a file that only exists remotely', () {
      final result = plan(remote: [file('notes.txt')]);

      expect(result.decisions, hasLength(1));
      expect(result.downloads.single.relativePath, 'notes.txt');
    });

    test('uploads a file that only exists locally', () {
      final result = plan(local: [file('notes.txt')]);

      expect(result.uploads.single.relativePath, 'notes.txt');
    });

    test('marks identical files as synced', () {
      final result = plan(
        local: [file('notes.txt', hash: 'same', baseHash: 'same')],
        remote: [file('notes.txt', hash: 'same', baseHash: 'same')],
      );

      expect(result.synced.single.relativePath, 'notes.txt');
      expect(result.hasWork, isFalse);
    });

    test('uploads when only the local hash changed', () {
      final result = plan(
        local: [file('notes.txt', hash: 'new', baseHash: 'old')],
        remote: [file('notes.txt', hash: 'old', baseHash: 'old')],
      );

      expect(result.uploads, hasLength(1));
    });

    test('downloads when only the remote hash changed', () {
      final result = plan(
        local: [file('notes.txt', hash: 'old', baseHash: 'old')],
        remote: [file('notes.txt', hash: 'new', baseHash: 'old')],
      );

      expect(result.downloads, hasLength(1));
    });

    test('flags a conflict when both sides changed', () {
      final result = plan(
        local: [file('notes.txt', hash: 'local-new', baseHash: 'old')],
        remote: [file('notes.txt', hash: 'remote-new', baseHash: 'old')],
      );

      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.single.conflict!.remoteDeviceId, 'device-b');
    });

    test('treats a missing baseline with different content as a conflict', () {
      final result = plan(
        local: [file('notes.txt', hash: 'local-new')],
        remote: [file('notes.txt', hash: 'remote-new')],
      );

      expect(result.hasConflicts, isTrue);
    });

    test('propagates a local deletion of an unchanged remote file', () {
      final result = plan(
        local: [file('notes.txt', hash: 'old', deleted: true)],
        remote: [file('notes.txt', hash: 'old', baseHash: 'old')],
      );

      expect(result.localDeletions, hasLength(1));
    });

    test('propagates a remote deletion of an unchanged local file', () {
      final result = plan(
        local: [file('notes.txt', hash: 'old', baseHash: 'old')],
        remote: [file('notes.txt', hash: 'old', deleted: true)],
      );

      expect(result.remoteDeletions, hasLength(1));
    });

    test('flags an edit-vs-delete conflict', () {
      final result = plan(
        local: [file('notes.txt', hash: 'edited', baseHash: 'old')],
        remote: [file('notes.txt', hash: 'old', baseHash: 'old', deleted: true)],
      );

      expect(result.hasConflicts, isTrue);
    });

    test('builds keep-both paths with device names and extensions', () {
      expect(
        SyncEngine.conflictCopyPath('notes/today.txt', 'Pixel 8'),
        'notes/today (Pixel 8).txt',
      );
      expect(
        SyncEngine.conflictCopyPath('archive.tar.gz', 'Laptop/PC'),
        'archive.tar (Laptop_PC).gz',
      );
      expect(
        SyncEngine.conflictCopyPath('README', ''),
        'README (Device)',
      );
    });
  });
}
