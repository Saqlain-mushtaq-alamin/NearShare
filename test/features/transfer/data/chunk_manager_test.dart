import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/chunk_manager.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ChunkManager', () {
    late Directory tempDir;
    late FileStorageService storage;
    late InMemoryTransferSessionRepository repository;
    late ChunkManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chunk_manager_test_');
      storage = FileStorageService(customDownloadPath: tempDir.path);
      repository = InMemoryTransferSessionRepository();
      manager = ChunkManager(repository: repository, storageService: storage);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<TransferSession> seed({
      int sizeInBytes = 2500,
      int chunkSize = 1024,
      String name = 'payload.bin',
    }) async {
      final session = TransferSession(
        transferId: 'cm-1',
        peerId: 'peer',
        peerName: 'Peer',
        direction: TransferDirection.receiving,
        status: TransferSessionStatus.inProgress,
        files: [
          TransferFile(
            name: name,
            sizeInBytes: sizeInBytes,
            mimeType: 'application/octet-stream',
            localPath: '/payload.bin',
          ),
        ],
        chunkSize: chunkSize,
        startedAt: DateTime.now(),
      );
      await repository.saveSession(session);
      return session;
    }

    test('splitFileIntoChunks honours the requested chunk size', () {
      const file = TransferFile(
        name: 'x.bin',
        sizeInBytes: 2500,
        mimeType: 'application/octet-stream',
        localPath: '/x.bin',
      );

      expect(manager.splitFileIntoChunks(file, 1024).length, 3);
      expect(manager.splitFileIntoChunks(file, 4096).length, 1);
      expect(manager.defaultSplit(file).length, 1);
    });

    test('writeChunk stores bytes and records them on the session', () async {
      final session = await seed();
      await manager.writeChunk(
        transferId: session.transferId,
        fileIndex: 0,
        chunkIndex: 0,
        bytes: List<int>.filled(1024, 1),
      );

      final updated = await repository.getSession(session.transferId);
      expect(updated!.receivedChunksForFile(0), [0]);
      expect(await manager.getMissingChunks(session.transferId, 0), [1, 2]);

      final chunkFile = await storage.chunkFileFor(session.transferId, 0, 0);
      expect(await chunkFile.exists(), isTrue);
      expect(await chunkFile.length(), 1024);
    });

    test('writeChunk rejects a payload whose size does not match the plan',
        () async {
      final session = await seed();
      expect(
        () => manager.writeChunk(
          transferId: session.transferId,
          fileIndex: 0,
          chunkIndex: 0,
          bytes: List<int>.filled(10, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writeChunk rejects a chunk index outside the plan', () async {
      final session = await seed();
      expect(
        () => manager.writeChunk(
          transferId: session.transferId,
          fileIndex: 0,
          chunkIndex: 99,
          bytes: List<int>.filled(1, 1),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('writeChunk for an unknown transfer throws', () async {
      expect(
        () => manager.writeChunk(
          transferId: 'missing',
          fileIndex: 0,
          chunkIndex: 0,
          bytes: const [],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('reconcileFile forgets chunks whose backing file was deleted',
        () async {
      final session = await seed();
      // 2500 bytes / 1024 => chunks of 1024, 1024, 452.
      final payloads = [
        List<int>.filled(1024, 0),
        List<int>.filled(1024, 1),
        List<int>.filled(452, 2),
      ];
      for (var i = 0; i < payloads.length; i++) {
        await manager.writeChunk(
          transferId: session.transferId,
          fileIndex: 0,
          chunkIndex: i,
          bytes: payloads[i],
        );
      }
      expect(await manager.isFileComplete(session.transferId, 0), isTrue);

      final chunkFile = await storage.chunkFileFor(session.transferId, 0, 1);
      await chunkFile.delete();

      expect(await manager.reconcileFile(session.transferId, 0), isTrue);
      final updated = await repository.getSession(session.transferId);
      expect(updated!.receivedChunksForFile(0), [0, 2]);
      expect(await manager.getMissingChunks(session.transferId, 0), [1]);
    });

    test('assembleFile concatenates chunks and records the destination',
        () async {
      final session = await seed(sizeInBytes: 30, chunkSize: 10, name: 'hi.txt');
      final expected = <int>[];
      for (var i = 0; i < 3; i++) {
        final payload = List<int>.filled(10, 65 + i);
        expected.addAll(payload);
        await manager.writeChunk(
          transferId: session.transferId,
          fileIndex: 0,
          chunkIndex: i,
          bytes: payload,
        );
      }

      final destination = await manager.assembleFile(session.transferId, 0);
      expect(await destination.readAsBytes(), expected);

      final updated = await repository.getSession(session.transferId);
      expect(updated!.fileSavePaths[0], destination.path);

      // Assembling again reuses the existing destination.
      expect(
        (await manager.assembleFile(session.transferId, 0)).path,
        destination.path,
      );
    });

    test('assembleFile refuses to run while chunks are missing', () async {
      final session = await seed(sizeInBytes: 30, chunkSize: 10);
      await manager.writeChunk(
        transferId: session.transferId,
        fileIndex: 0,
        chunkIndex: 0,
        bytes: List<int>.filled(10, 65),
      );

      expect(
        () => manager.assembleFile(session.transferId, 0),
        throwsA(isA<StateError>()),
      );
    });

    test('zero byte file is complete without any chunk', () async {
      final session = await seed(sizeInBytes: 0);
      expect(await manager.isFileComplete(session.transferId, 0), isTrue);
      final destination = await manager.assembleFile(session.transferId, 0);
      expect(await destination.length(), 0);
      expect(p.basename(destination.path), session.files.single.name);
    });

    test('discardTransfer clears chunk bookkeeping for the session', () async {
      final session = await seed();
      await manager.writeChunk(
        transferId: session.transferId,
        fileIndex: 0,
        chunkIndex: 0,
        bytes: List<int>.filled(1024, 1),
      );

      await manager.discardTransfer(session.transferId);

      final updated = await repository.getSession(session.transferId);
      expect(updated!.receivedChunksForFile(0), isEmpty);
      expect(
        await (await storage.chunkFileFor(session.transferId, 0, 0)).exists(),
        isFalse,
      );
    });
  });
}
