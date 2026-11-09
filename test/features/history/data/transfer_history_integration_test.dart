import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TransferManager history integration', () {
    late Directory senderDir;
    late Directory receiverDir;
    late FileStorageService senderStorage;
    late FileStorageService receiverStorage;
    late DriftHistoryRepository senderHistory;
    late DriftHistoryRepository receiverHistory;
    late DriftTransferSessionRepository senderSessions;
    late TransferServer receiverServer;
    late TransferManager senderManager;
    late Device target;
    late Device localDevice;
    late int receiverPort;

    setUp(() async {
      senderDir = await Directory.systemTemp.createTemp('hist_sender_');
      receiverDir = await Directory.systemTemp.createTemp('hist_receiver_');
      senderStorage = FileStorageService(customDownloadPath: senderDir.path);
      receiverStorage = FileStorageService(customDownloadPath: receiverDir.path);

      senderHistory = DriftHistoryRepository.inMemory();
      receiverHistory = DriftHistoryRepository.inMemory();
      senderSessions = DriftTransferSessionRepository.inMemory();

      receiverServer = TransferServer(
        storageService: receiverStorage,
        sessionRepository: DriftTransferSessionRepository.inMemory(),
        historyRepository: receiverHistory,
      );
      receiverPort = await receiverServer.start(port: 0);

      senderManager = TransferManager(
        storageService: senderStorage,
        sessionRepository: senderSessions,
        historyRepository: senderHistory,
      );

      target = Device(
        id: 'receiver',
        name: 'Receiver',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: receiverPort,
        discoveredAt: DateTime.now(),
      );
      localDevice = Device(
        id: 'sender',
        name: 'Sender',
        platform: 'windows',
        ipAddress: '127.0.0.1',
        port: 53317,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await senderManager.dispose();
      await receiverServer.dispose();
      await senderHistory.close();
      await receiverHistory.close();
      for (final dir in [senderDir, receiverDir]) {
        if (await dir.exists()) {
          try {
            await dir.delete(recursive: true);
          } on FileSystemException {
            // discardSession fires the temp cleanup without awaiting it, so a
            // background delete may still be touching this directory.
          }
        }
      }
    });

    Future<File> writeSource(String name, String contents) async {
      final file = File(p.join(senderDir.path, name));
      await file.writeAsString(contents);
      return file;
    }

    TransferFile fileOf(File file) {
      return TransferFile(
        name: p.basename(file.path),
        sizeInBytes: file.lengthSync(),
        mimeType: 'text/plain',
        localPath: file.path,
      );
    }

    test('a completed transfer is saved to both sides of the history',
        () async {
      receiverServer.onIncomingRequest.listen((request) {
        receiverServer.respondToRequest(request.transferId, true);
      });

      final source = await writeSource('done.txt', 'complete me');
      final progress = await senderManager.sendFiles(
        target: target,
        files: [fileOf(source)],
        localDevice: localDevice,
        transferId: 'hist-done',
      );

      expect(progress.status, TransferStatus.completed);

      final senderRecords = await senderHistory.getAllRecords().first;
      expect(senderRecords, hasLength(1));
      final sent = senderRecords.single;
      expect(sent.transferId, 'hist-done');
      expect(sent.direction, TransferDirection.sending);
      expect(sent.peerDeviceName, 'Receiver');
      expect(sent.totalFiles, 1);
      expect(sent.totalSizeBytes, await source.length());
      expect(sent.status, TransferRecordStatus.completed);
      expect(sent.completedAt, isNotNull);
      expect(sent.files.single.status, TransferRecordStatus.completed);
      expect(sent.files.single.localPath, source.path);

      final receiverRecords = await receiverHistory.getAllRecords().first;
      expect(receiverRecords, hasLength(1));
      final received = receiverRecords.single;
      expect(received.transferId, 'hist-done');
      expect(received.direction, TransferDirection.receiving);
      expect(received.status, TransferRecordStatus.completed);
      expect(received.files.single.localPath, isNotEmpty);
    });

    test('a multi-file transfer records every file', () async {
      receiverServer.onIncomingRequest.listen((request) {
        receiverServer.respondToRequest(request.transferId, true);
      });

      final a = await writeSource('a.txt', 'aaaa');
      final b = await writeSource('b.txt', 'bbbbbb');

      final progress = await senderManager.sendFiles(
        target: target,
        files: [fileOf(a), fileOf(b)],
        localDevice: localDevice,
        transferId: 'hist-multi',
      );

      expect(progress.status, TransferStatus.completed);

      final sent = (await senderHistory.getAllRecords().first).single;
      expect(sent.totalFiles, 2);
      expect(sent.files.map((f) => f.fileName), ['a.txt', 'b.txt']);
      expect(sent.files.every((f) => f.isCompleted), isTrue);

      final received = (await receiverHistory.getAllRecords().first).single;
      expect(received.files, hasLength(2));
      expect(received.files.every((f) => f.isCompleted), isTrue);
    });

    test('a transfer whose source disappears is recorded as failed', () async {
      receiverServer.onIncomingRequest.listen((request) {
        receiverServer.respondToRequest(request.transferId, true);
      });

      final missing = File(p.join(senderDir.path, 'never-created.txt'));
      final progress = await senderManager.sendFiles(
        target: target,
        files: [
          TransferFile(
            name: 'never-created.txt',
            sizeInBytes: 20,
            mimeType: 'text/plain',
            localPath: missing.path,
          ),
        ],
        localDevice: localDevice,
        transferId: 'hist-fail',
      );

      expect(progress.status, TransferStatus.failed);

      final records = await senderHistory.getAllRecords().first;
      expect(records.single.transferId, 'hist-fail');
      expect(records.single.status, TransferRecordStatus.failed);
      expect(records.single.files.single.status, TransferRecordStatus.failed);
    });

    test('a rejected transfer is recorded as cancelled on the sender',
        () async {
      receiverServer.onIncomingRequest.listen((request) {
        receiverServer.respondToRequest(request.transferId, false);
      });

      final source = await writeSource('rejected.txt', 'nobody wants this');
      final progress = await senderManager.sendFiles(
        target: target,
        files: [fileOf(source)],
        localDevice: localDevice,
        transferId: 'hist-reject',
      );

      expect(progress.status, TransferStatus.rejected);

      final records = await senderHistory.getAllRecords().first;
      expect(records.single.transferId, 'hist-reject');
      expect(records.single.status, TransferRecordStatus.cancelled);
    });

    test('a cancelled session is recorded as cancelled', () async {
      final source = await writeSource('cancelled.txt', 'abort abort');
      final session = TransferSession(
        transferId: 'hist-cancel',
        peerId: target.id,
        peerName: target.name,
        peerIp: target.ipAddress,
        peerPort: target.port,
        direction: TransferDirection.sending,
        status: TransferSessionStatus.paused,
        files: [fileOf(source)],
        chunkSize: 1024,
        startedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );
      await senderSessions.saveSession(session);

      await senderManager.cancelTransfer('hist-cancel');

      final records = await senderHistory.getAllRecords().first;
      expect(records.single.transferId, 'hist-cancel');
      expect(records.single.status, TransferRecordStatus.cancelled);
      expect(records.single.direction, TransferDirection.sending);
    });

    test('discarding an unfinished session is recorded as cancelled',
        () async {
      final source = await writeSource('discarded.txt', 'give up');
      final session = TransferSession(
        transferId: 'hist-discard',
        peerId: target.id,
        peerName: target.name,
        direction: TransferDirection.sending,
        status: TransferSessionStatus.paused,
        files: [fileOf(source)],
        chunkSize: 1024,
        startedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );
      await senderSessions.saveSession(session);

      await senderManager.discardSession('hist-discard');

      final records = await senderHistory.getAllRecords().first;
      expect(records.single.transferId, 'hist-discard');
      expect(records.single.status, TransferRecordStatus.cancelled);
      expect(await senderSessions.getSession('hist-discard'), isNull);
    });

    test('a paused transfer is not written to history', () async {
      final unreachable = Device(
        id: 'gone',
        name: 'Gone',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: 1,
        discoveredAt: DateTime.now(),
      );

      final source = await writeSource('paused.txt', 'half way');
      final progress = await senderManager.sendFiles(
        target: unreachable,
        files: [fileOf(source)],
        localDevice: localDevice,
        transferId: 'hist-pause',
      );

      expect(progress.status, TransferStatus.inProgress);
      expect(progress.isConnectionLost, isTrue);

      final records = await senderHistory.getAllRecords().first;
      expect(records, isEmpty);
    });

    test('a failed history write never breaks the transfer', () async {
      receiverServer.onIncomingRequest.listen((request) {
        receiverServer.respondToRequest(request.transferId, true);
      });

      final broken = _ThrowingHistoryRepository();
      final manager = TransferManager(
        storageService: senderStorage,
        sessionRepository: DriftTransferSessionRepository.inMemory(),
        historyRepository: broken,
      );
      addTearDown(manager.dispose);

      final source = await writeSource('resilient.txt', 'still succeeds');
      final progress = await manager.sendFiles(
        target: target,
        files: [fileOf(source)],
        localDevice: localDevice,
        transferId: 'hist-resilient',
      );

      expect(progress.status, TransferStatus.completed);
      expect(broken.saveCalls, 1);

      await manager.dispose();
    });
  });
}

class _ThrowingHistoryRepository implements HistoryRepository {
  int saveCalls = 0;

  @override
  Future<void> saveTransferRecord(TransferRecord record) async {
    saveCalls++;
    throw StateError('disk full');
  }

  @override
  Stream<List<TransferRecord>> getAllRecords({
    TransferDirection? filter,
    String? deviceFilter,
    String? search,
  }) async* {
    yield const [];
  }

  @override
  Stream<List<TransferRecord>> getRecordsByDevice(String deviceId) async* {
    yield const [];
  }

  @override
  Future<TransferRecord?> getRecordById(String transferId) async => null;

  @override
  Future<void> deleteRecord(String transferId) async {}

  @override
  Future<void> clearAllHistory() async {}

  @override
  Stream<List<TransferRecord>> getRecentRecords(int limit) async* {
    yield const [];
  }

  @override
  Future<void> close() async {}
}
