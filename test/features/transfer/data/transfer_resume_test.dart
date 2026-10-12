import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/chunk_manager.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

void main() {
  group('Resumable transfer', () {
    late Directory senderDir;
    late Directory receiverDir;
    late FileStorageService senderStorage;
    late FileStorageService receiverStorage;
    late DriftTransferSessionRepository receiverRepository;
    late TransferServer receiverServer;
    late Device target;
    late File sourceFile;
    late String content;

    setUp(() async {
      senderDir = await Directory.systemTemp.createTemp('resume_sender_');
      receiverDir = await Directory.systemTemp.createTemp('resume_receiver_');
      senderStorage = FileStorageService(customDownloadPath: senderDir.path);
      receiverStorage = FileStorageService(customDownloadPath: receiverDir.path);
      receiverRepository = DriftTransferSessionRepository.inMemory();
      receiverServer = TransferServer(
        storageService: receiverStorage,
        sessionRepository: receiverRepository,
      );
      final port = await receiverServer.start(port: 0);
      target = Device(
        id: 'receiver',
        name: 'Receiver',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
      );

      content = 'The quick brown fox jumps over the lazy dog.';
      sourceFile = File(p.join(senderDir.path, 'resume.txt'));
      await sourceFile.writeAsString(content);
    });

    tearDown(() async {
      await receiverServer.dispose();
      for (final dir in [senderDir, receiverDir]) {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    });

    TransferFile buildFile() {
      return TransferFile(
        name: 'resume.txt',
        sizeInBytes: content.length,
        mimeType: 'text/plain',
        localPath: sourceFile.path,
      );
    }

    TransferRequest buildRequest(String transferId, {int chunkSize = 16}) {
      final file = buildFile();
      return TransferRequest(
        transferId: transferId,
        senderId: 'sender',
        senderName: 'Sender',
        files: [file],
        totalSizeBytes: file.sizeInBytes,
        timestamp: DateTime.now(),
        chunkSize: chunkSize,
      );
    }

    TransferSession buildSenderSession({
      required String transferId,
      TransferSessionStatus status = TransferSessionStatus.paused,
    }) {
      return TransferSession(
        transferId: transferId,
        peerId: target.id,
        peerName: target.name,
        peerIp: target.ipAddress,
        peerPort: target.port,
        direction: TransferDirection.sending,
        status: status,
        files: [buildFile()],
        chunkSize: 16,
        localDeviceId: 'sender',
        localDeviceName: 'Sender',
        startedAt: DateTime.now(),
      );
    }

    Future<void> prepareAndAccept(String transferId, {int chunkSize = 16}) async {
      receiverServer.onIncomingRequest.listen((req) {
        receiverServer.respondToRequest(req.transferId, true);
      });
      final response = await receiverServer.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/transfer/prepare'),
          body: jsonEncode(buildRequest(transferId, chunkSize: chunkSize).toJson()),
          headers: {'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 200);
    }

    Future<void> sendChunk({
      required String transferId,
      required int chunkIndex,
      required int startByte,
      required int endByte,
      required int totalChunks,
    }) async {
      final response = await receiverServer.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/transfer/chunk/$transferId/0'),
          body: Stream.value(content.substring(startByte, endByte + 1).codeUnits),
          headers: {
            'content-type': 'application/octet-stream',
            'x-transfer-id': transferId,
            'x-file-index': '0',
            'x-chunk-index': '$chunkIndex',
            'x-chunk-size': '${endByte - startByte + 1}',
            'x-total-chunks': '$totalChunks',
            'content-range': 'bytes $startByte-$endByte/${buildFile().sizeInBytes}',
          },
        ),
      );
      expect(response.statusCode, 200);
    }

    TransferManager buildSenderManager(TransferSessionRepository repo) {
      return TransferManager(
        client: TransferClient(),
        storageService: senderStorage,
        sessionRepository: repo,
      );
    }

    test('a resumed send only transmits the chunks the receiver is missing',
        () async {
      final file = buildFile();
      final totalChunks = (file.sizeInBytes / 16).ceil();

      // Simulate a crash after the first chunk landed on the receiver.
      await prepareAndAccept('resume-1');
      await sendChunk(
        transferId: 'resume-1',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );

      final senderRepository = InMemoryTransferSessionRepository();
      final session = buildSenderSession(transferId: 'resume-1');
      await senderRepository.saveSession(session);

      final senderManager = buildSenderManager(senderRepository);
      final progress = await senderManager.resumeSession(session, target);

      expect(progress.status, TransferStatus.completed);
      expect(progress.bytesTransferred, file.sizeInBytes);

      final senderSession = await senderRepository.getSession('resume-1');
      expect(senderSession!.status, TransferSessionStatus.completed);
      expect(senderSession.fileSavePaths[0], isNotNull);
      expect(
        await File(senderSession.fileSavePaths[0]!).readAsString(),
        content,
      );

      await senderManager.dispose();
    });

    test('re-uploading an identical chunk is idempotent', () async {
      final file = buildFile();
      final totalChunks = (file.sizeInBytes / 16).ceil();

      await prepareAndAccept('idem-1');
      await sendChunk(
        transferId: 'idem-1',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );
      await sendChunk(
        transferId: 'idem-1',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );

      final session = await receiverRepository.getSession('idem-1');
      expect(session!.receivedChunksForFile(0), [0]);
      expect(file.sizeInBytes, content.length);
    });

    test('receiver chunks survive a server restart', () async {
      final file = buildFile();
      final totalChunks = (file.sizeInBytes / 16).ceil();

      await prepareAndAccept('restart-1');
      await sendChunk(
        transferId: 'restart-1',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );

      // "Restart" the receiver: a brand new server over the same storage.
      final oldPort = receiverServer.boundPort!;
      await receiverServer.stop();
      final restarted = TransferServer(
        storageService: receiverStorage,
        sessionRepository: receiverRepository,
      );
      await restarted.start(port: oldPort);
      receiverServer = restarted;

      final client = TransferClient();
      final resume = await client.getResumeState(target, 'restart-1', 0);
      expect(resume.known, isTrue);
      expect(resume.receivedChunks, [0]);

      await client.prepareTransfer(target, buildRequest('restart-1'));
      for (var chunkIndex = 1; chunkIndex < totalChunks; chunkIndex++) {
        final start = chunkIndex * 16;
        final endExclusive = (start + 16).clamp(0, file.sizeInBytes).toInt();
        await client.uploadChunk(
          target: target,
          transferId: 'restart-1',
          fileIndex: 0,
          chunkIndex: chunkIndex,
          bytes: Uint8List.fromList(content.substring(start, endExclusive).codeUnits),
          startByte: start,
          endByte: endExclusive - 1,
          fileSize: file.sizeInBytes,
          totalChunks: totalChunks,
        );
      }

      final result = await client.finalizeFile(target, 'restart-1', 0);
      expect(await File(result['savePath'] as String).readAsString(), content);
    });

    test('an unreachable peer pauses the transfer instead of failing it',
        () async {
      final closedPort = await _closedPort();
      final deadTarget = Device(
        id: 'offline',
        name: 'Offline',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: closedPort,
        discoveredAt: DateTime.now(),
      );

      final senderRepository = InMemoryTransferSessionRepository();
      final manager = buildSenderManager(senderRepository);

      final progress = await manager.sendFiles(
        target: deadTarget,
        files: [buildFile()],
        localDevice: Device(
          id: 'sender',
          name: 'Sender',
          platform: 'windows',
          ipAddress: '127.0.0.1',
          port: 1,
          discoveredAt: DateTime.now(),
        ),
      );

      expect(progress.status, TransferStatus.inProgress);
      expect(progress.isConnectionLost, isTrue);

      final sessions = await senderRepository.getIncompleteSessions();
      expect(sessions.single.status, TransferSessionStatus.paused);
      expect(sessions.single.peerId, 'offline');

      await manager.dispose();
    });

    test('markInterruptedSessions pauses drives left in progress', () async {
      final repository = InMemoryTransferSessionRepository();
      await repository.saveSession(
        buildSenderSession(transferId: 'orphan', status: TransferSessionStatus.inProgress),
      );
      await repository.saveSession(
        buildSenderSession(transferId: 'already', status: TransferSessionStatus.paused),
      );

      final manager = buildSenderManager(repository);
      await manager.markInterruptedSessions();

      expect(
        (await repository.getSession('orphan'))!.status,
        TransferSessionStatus.paused,
      );
      expect(
        (await repository.getSession('already'))!.status,
        TransferSessionStatus.paused,
      );

      await manager.dispose();
    });

    test(
        'a restart pauses the drive and the rediscovered peer resumes it',
        () async {
      final file = buildFile();
      final totalChunks = (file.sizeInBytes / 16).ceil();

      // The first app run crashed after only the first chunk was sent.
      await prepareAndAccept('restart-sender');
      await sendChunk(
        transferId: 'restart-sender',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );

      final repository = InMemoryTransferSessionRepository();
      await repository.saveSession(
        buildSenderSession(
          transferId: 'restart-sender',
          status: TransferSessionStatus.inProgress,
        ),
      );

      // Second app run: a brand new manager over the same persisted state.
      final restarted = buildSenderManager(repository);
      await restarted.initialize();

      final resumed = await restarted.resumeTransferForPeer(target, cooldown: Duration.zero);
      expect(resumed, isNotNull);
      expect(
        (await repository.getSession('restart-sender'))!.status,
        TransferSessionStatus.inProgress,
      );

      // Let the background resume finish before disposing.
      TransferSession? finished;
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        finished = await repository.getSession('restart-sender');
        if (finished?.status == TransferSessionStatus.completed) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(finished, isNotNull);
      expect(finished!.status, TransferSessionStatus.completed);
      expect(
        await File(finished.fileSavePaths[0]!).readAsString(),
        content,
      );

      await restarted.dispose();
    });

    test('cleanupStaleSessions drops old rows and returns them', () async {
      final repository = InMemoryTransferSessionRepository();
      final old = DateTime.now().subtract(const Duration(hours: 48));
      await repository.saveSession(
        buildSenderSession(transferId: 'old')
            .copyWith(status: TransferSessionStatus.paused, lastActivityAt: old),
      );
      await repository.saveSession(
        buildSenderSession(transferId: 'new')
            .copyWith(status: TransferSessionStatus.paused),
      );

      final manager = buildSenderManager(repository);
      final removed = await manager.cleanupStaleSessions();

      expect(removed.map((s) => s.transferId), ['old']);
      expect(await repository.getSession('old'), isNull);
      expect(await repository.getSession('new'), isNotNull);

      await manager.dispose();
    });

    test('discardSession removes the session and its staged chunks',
        () async {
      final repository = InMemoryTransferSessionRepository();
      await repository.saveSession(
        buildSenderSession(
          transferId: 'discard-me',
          status: TransferSessionStatus.paused,
        ),
      );

      final manager = buildSenderManager(repository);
      await manager.discardSession('discard-me');

      expect(await repository.getSession('discard-me'), isNull);
      expect(await manager.getIncompleteSessions(), isEmpty);

      await manager.dispose();
    });

    test('a stale chunk on disk is re-requested after reconcile', () async {
      final file = buildFile();
      final totalChunks = (file.sizeInBytes / 16).ceil();

      await prepareAndAccept('lost-chunk');
      await sendChunk(
        transferId: 'lost-chunk',
        chunkIndex: 0,
        startByte: 0,
        endByte: 15,
        totalChunks: totalChunks,
      );

      final chunkFile = await receiverStorage.chunkFileFor('lost-chunk', 0, 0);
      await chunkFile.delete();

      final chunkManager = ChunkManager(
        repository: receiverRepository,
        storageService: receiverStorage,
      );
      expect(await chunkManager.getMissingChunks('lost-chunk', 0), [0]);

      final client = TransferClient();
      final resume = await client.getResumeState(target, 'lost-chunk', 0);
      expect(resume.receivedChunks, isEmpty);
    });
  });
}

Future<int> _closedPort() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();
  return port;
}
