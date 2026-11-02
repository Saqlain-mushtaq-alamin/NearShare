import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';
import 'package:nearshare/features/merge_space/domain/sync_conflict.dart';

MergeSpaceFile sampleFile(String path, {bool deleted = false}) {
  return MergeSpaceFile(
    relativePath: path,
    hash: 'hash-$path',
    sizeBytes: 12,
    modifiedAt: DateTime(2026, 1, 1),
    isDeleted: deleted,
    originDeviceId: 'device-a',
  );
}

void main() {
  group('DriftMergeSpaceRepository', () {
    late DriftMergeSpaceRepository repository;

    setUp(() {
      repository = DriftMergeSpaceRepository.inMemory();
    });

    tearDown(() => repository.close());

    test('persists and filters tombstoned files', () async {
      await repository.saveFiles([
        sampleFile('keep.txt'),
        sampleFile('gone.txt', deleted: true),
      ]);

      final live = await repository.getAllFiles();
      final all = await repository.getAllFiles(includeDeleted: true);

      expect(live.map((file) => file.relativePath), ['keep.txt']);
      expect(all, hasLength(2));
      expect(
        (await repository.getFile('gone.txt'))!.isDeleted,
        isTrue,
      );
    });

    test('updates a file in place', () async {
      await repository.saveFile(sampleFile('notes.txt'));
      await repository.saveFile(
        sampleFile('notes.txt').copyWith(hash: 'new', baseHash: 'old'),
      );

      final stored = await repository.getFile('notes.txt');
      expect(stored!.hash, 'new');
      expect(stored.baseHash, 'old');
      expect(await repository.getAllFiles(includeDeleted: true), hasLength(1));
    });

    test('stores paired devices with their group id', () async {
      await repository.saveDevice(
        PairedDevice(
          deviceId: 'device-b',
          deviceName: 'Pixel',
          platform: 'android',
          groupId: 'group-1',
          pairedAt: DateTime(2026, 1, 1),
        ),
      );

      final devices = await repository.getDevices();

      expect(devices.single.deviceName, 'Pixel');
      expect(devices.single.groupId, 'group-1');
    });

    test('saves and resolves conflicts', () async {
      final conflict = SyncConflict(
        relativePath: 'notes.txt',
        localVersion: sampleFile('notes.txt'),
        remoteVersion: sampleFile('notes.txt').copyWith(hash: 'remote'),
        remoteDeviceId: 'device-b',
        detectedAt: DateTime(2026, 1, 2),
      );

      final stored = await repository.saveConflict(conflict);
      expect(stored.id, isNotNull);

      final open = await repository.getConflicts();
      expect(open, hasLength(1));

      await repository.resolveConflict(stored.id!);

      expect(await repository.getConflicts(), isEmpty);
      expect(
        await repository.getConflicts(unresolvedOnly: false),
        hasLength(1),
      );
    });

    test('clears every table', () async {
      await repository.saveFile(sampleFile('notes.txt'));
      await repository.saveDevice(
        PairedDevice(
          deviceId: 'device-b',
          deviceName: 'Pixel',
          platform: 'android',
          groupId: 'group-1',
          pairedAt: DateTime(2026, 1, 1),
        ),
      );
      await repository.saveConflict(
        SyncConflict(
          relativePath: 'notes.txt',
          localVersion: sampleFile('notes.txt'),
          remoteVersion: sampleFile('notes.txt').copyWith(hash: 'remote'),
          remoteDeviceId: 'device-b',
          detectedAt: DateTime(2026, 1, 2),
        ),
      );

      await repository.clearFiles();
      await repository.clearDevices();
      await repository.clearConflicts();

      expect(await repository.getAllFiles(includeDeleted: true), isEmpty);
      expect(await repository.getDevices(), isEmpty);
      expect(await repository.getConflicts(), isEmpty);
    });
  });
}
