import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/file_index_service.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';

void main() {
  late Directory temp;
  late MergeSpaceStorage storage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('merge_storage_test_');
    storage = MergeSpaceStorage(customRootPath: temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('MergeSpaceStorage', () {
    test('writes, reads and deletes files atomically', () async {
      await storage.writeBytes('notes/hello.txt', [1, 2, 3]);

      expect(await storage.exists('notes/hello.txt'), isTrue);
      expect(await storage.readBytes('notes/hello.txt'), [1, 2, 3]);

      await storage.delete('notes/hello.txt');
      expect(await storage.exists('notes/hello.txt'), isFalse);
    });

    test('normalizes separators and rejects traversal', () {
      expect(
        MergeSpaceStorage.normalizeRelative(r'notes\sub\file.txt'),
        'notes/sub/file.txt',
      );
      expect(
        () => MergeSpaceStorage.normalizeRelative('../outside.txt'),
        throwsArgumentError,
      );
      expect(
        () => MergeSpaceStorage.normalizeRelative('notes/../outside.txt'),
        throwsArgumentError,
      );
      expect(
        () => MergeSpaceStorage.normalizeRelative('/'),
        throwsArgumentError,
      );
    });

    test('skips hidden files and staging files', () async {
      await storage.writeBytes('visible.txt', [1]);
      await storage.writeBytes('.hidden.txt', [1]);
      await storage.writeBytes('notes.txt.merge-tmp', [1]);

      final names = (await storage.listFiles()).map((file) => file.uri.pathSegments.last);

      expect(names, contains('visible.txt'));
      expect(names, isNot(contains('.hidden.txt')));
      expect(names, isNot(contains('notes.txt.merge-tmp')));
    });
  });

  group('FileIndexService', () {
    test('hashes file contents with SHA-256', () async {
      await storage.writeBytes('hello.txt', 'hello'.codeUnits);
      final index = FileIndexService(storage: storage);
      final file = await storage.resolve('hello.txt');

      expect(
        await index.hashFile(file),
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });

    test('indexes new files with size and origin', () async {
      await storage.writeBytes('notes/today.txt', [1, 2, 3, 4]);
      final index = FileIndexService(storage: storage);

      final scanned = await index.scan(
        localDeviceId: 'device-a',
        previous: const [],
      );

      expect(scanned, hasLength(1));
      expect(scanned.single.relativePath, 'notes/today.txt');
      expect(scanned.single.sizeBytes, 4);
      expect(scanned.single.originDeviceId, 'device-a');
      expect(scanned.single.isDeleted, isFalse);
    });

    test('keeps the baseline when a file is modified', () async {
      await storage.writeBytes('notes.txt', [1]);
      final index = FileIndexService(storage: storage);
      final first = await index.scan(
        localDeviceId: 'device-a',
        previous: const [],
      );

      first[0] = first[0].copyWith(baseHash: first[0].hash);
      await storage.writeBytes('notes.txt', [2, 3]);
      final second = await index.scan(
        localDeviceId: 'device-a',
        previous: first,
      );

      expect(second.single.hash, isNot(first.single.hash));
      expect(second.single.baseHash, first.single.hash);
    });

    test('creates tombstones for deleted files', () async {
      await storage.writeBytes('gone.txt', [1]);
      final index = FileIndexService(storage: storage);
      final first = await index.scan(
        localDeviceId: 'device-a',
        previous: const [],
      );

      await storage.delete('gone.txt');
      final second = await index.scan(
        localDeviceId: 'device-a',
        previous: first,
      );

      expect(second.single.relativePath, 'gone.txt');
      expect(second.single.isDeleted, isTrue);
      expect(second.single.originDeviceId, 'device-a');
    });
  });
}
