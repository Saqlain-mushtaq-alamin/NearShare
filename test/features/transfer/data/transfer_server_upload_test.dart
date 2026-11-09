import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('TransferServer Chunk Upload Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;
    late TransferServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearshare_upload_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
      server = TransferServer(storageService: storageService);
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Uri url(String path) => Uri.parse('http://localhost:53317$path');

    Future<void> prepareAndAccept(TransferRequest request) async {
      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      final prepRes = await server.handler(
        Request(
          'POST',
          url('/api/v1/transfer/prepare'),
          body: jsonEncode(request.toJson()),
          headers: {'content-type': 'application/json'},
        ),
      );
      expect(prepRes.statusCode, 200);
    }

    Future<Response> uploadChunk({
      required String transferId,
      required int fileIndex,
      required int chunkIndex,
      required List<int> bytes,
      required int startByte,
      required int endByte,
      required int fileSize,
      required int totalChunks,
    }) {
      return Future.value(
        server.handler(
          Request(
            'POST',
            url('/api/v1/transfer/chunk/$transferId/$fileIndex'),
            body: Stream.value(bytes),
            headers: {
              'content-type': 'application/octet-stream',
              'x-transfer-id': transferId,
              'x-file-index': '$fileIndex',
              'x-chunk-index': '$chunkIndex',
              'x-chunk-size': '${bytes.length}',
              'x-total-chunks': '$totalChunks',
              'content-range': 'bytes $startByte-$endByte/$fileSize',
            },
          ),
        ),
      );
    }

    test('chunk route stores every chunk, finalize assembles the file',
        () async {
      const fileContent = 'Hello World!!';
      final request = TransferRequest(
        transferId: 'upload-tx-1',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'hello.txt',
            sizeInBytes: 13,
            mimeType: 'text/plain',
            localPath: '/hello.txt',
          ),
        ],
        totalSizeBytes: 13,
        timestamp: DateTime.now(),
      );

      await prepareAndAccept(request);

      TransferProgress? completedProgress;
      server.onProgress.listen((p) {
        if (p.status == TransferStatus.completed) {
          completedProgress = p;
        }
      });

      final chunkRes = await uploadChunk(
        transferId: 'upload-tx-1',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: utf8.encode(fileContent),
        startByte: 0,
        endByte: 12,
        fileSize: 13,
        totalChunks: 1,
      );
      expect(chunkRes.statusCode, 200);

      final chunkBody =
          jsonDecode(await chunkRes.readAsString()) as Map<String, dynamic>;
      expect(chunkBody['status'], 'received');
      expect(chunkBody['fileComplete'], isTrue);
      expect(chunkBody['missingChunks'], isEmpty);

      final finalizeRes = await server.handler(
        Request(
          'POST',
          url('/api/v1/transfer/finalize/upload-tx-1/0'),
        ),
      );
      expect(finalizeRes.statusCode, 200);

      final body =
          jsonDecode(await finalizeRes.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'completed');
      expect(body['fileIndex'], 0);

      final savedPath = body['savePath'] as String;
      final savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsString(), fileContent);

      expect(completedProgress, isNotNull);
      expect(completedProgress!.status, TransferStatus.completed);
    });

    test('zero-byte files finalize without sending chunks', () async {
      final request = TransferRequest(
        transferId: 'upload-tx-empty',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'empty.bin',
            sizeInBytes: 0,
            mimeType: 'application/octet-stream',
            localPath: '/empty.bin',
          ),
        ],
        totalSizeBytes: 0,
        timestamp: DateTime.now(),
      );

      await prepareAndAccept(request);

      final finalizeRes = await server.handler(
        Request('POST', url('/api/v1/transfer/finalize/upload-tx-empty/0')),
      );
      expect(finalizeRes.statusCode, 200);

      final body =
          jsonDecode(await finalizeRes.readAsString()) as Map<String, dynamic>;
      final savedFile = File(body['savePath'] as String);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.length(), 0);
    });

    test(
        'finalize of a partially received file answers 409 with missing chunks',
        () async {
      const fileContent = 'Hello World!!';
      final request = TransferRequest(
        transferId: 'upload-tx-2',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'split.txt',
            sizeInBytes: 13,
            mimeType: 'text/plain',
            localPath: '/split.txt',
          ),
        ],
        totalSizeBytes: 13,
        timestamp: DateTime.now(),
        chunkSize: 6,
      );

      await prepareAndAccept(request);

      final first = await uploadChunk(
        transferId: 'upload-tx-2',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: utf8.encode('Hello '),
        startByte: 0,
        endByte: 5,
        fileSize: 13,
        totalChunks: 3,
      );
      expect(first.statusCode, 200);

      final finalizeRes = await server.handler(
        Request('POST', url('/api/v1/transfer/finalize/upload-tx-2/0')),
      );
      expect(finalizeRes.statusCode, 409);

      final body =
          jsonDecode(await finalizeRes.readAsString()) as Map<String, dynamic>;
      expect(body['missingChunks'], [1, 2]);

      for (var chunkIndex = 1; chunkIndex < 3; chunkIndex++) {
        final start = chunkIndex * 6;
        final text = chunkIndex == 1 ? 'World!' : '!';
        final res = await uploadChunk(
          transferId: 'upload-tx-2',
          fileIndex: 0,
          chunkIndex: chunkIndex,
          bytes: utf8.encode(text),
          startByte: start,
          endByte: start + text.length - 1,
          fileSize: 13,
          totalChunks: 3,
        );
        expect(res.statusCode, 200);
      }

      final retry = await server.handler(
        Request('POST', url('/api/v1/transfer/finalize/upload-tx-2/0')),
      );
      expect(retry.statusCode, 200);

      final retryBody =
          jsonDecode(await retry.readAsString()) as Map<String, dynamic>;
      final savedFile = File(retryBody['savePath'] as String);
      expect(await savedFile.readAsString(), fileContent);
    });

    test('chunk upload for an unknown transfer answers 404', () async {
      final res = await uploadChunk(
        transferId: 'missing-tx',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: utf8.encode('nope'),
        startByte: 0,
        endByte: 3,
        fileSize: 4,
        totalChunks: 1,
      );
      expect(res.statusCode, 404);
    });

    test('chunk upload whose range does not match the plan answers 400',
        () async {
      final request = TransferRequest(
        transferId: 'upload-tx-3',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'ranged.txt',
            sizeInBytes: 13,
            mimeType: 'text/plain',
            localPath: '/ranged.txt',
          ),
        ],
        totalSizeBytes: 13,
        timestamp: DateTime.now(),
        chunkSize: 6,
      );

      await prepareAndAccept(request);

      final res = await uploadChunk(
        transferId: 'upload-tx-3',
        fileIndex: 0,
        chunkIndex: 1,
        bytes: utf8.encode('Hello '),
        startByte: 0,
        endByte: 5,
        fileSize: 13,
        totalChunks: 3,
      );
      expect(res.statusCode, 400);
    });

    test('resume endpoint reports received chunks for a known transfer',
        () async {
      final request = TransferRequest(
        transferId: 'upload-tx-4',
        senderId: 'dev-sender',
        senderName: 'Sender',
        files: const [
          TransferFile(
            name: 'resume.txt',
            sizeInBytes: 13,
            mimeType: 'text/plain',
            localPath: '/resume.txt',
          ),
        ],
        totalSizeBytes: 13,
        timestamp: DateTime.now(),
        chunkSize: 6,
      );

      await prepareAndAccept(request);

      await uploadChunk(
        transferId: 'upload-tx-4',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: utf8.encode('Hello '),
        startByte: 0,
        endByte: 5,
        fileSize: 13,
        totalChunks: 3,
      );

      final res = await server.handler(
        Request('GET', url('/api/v1/transfer/resume/upload-tx-4/0')),
      );
      expect(res.statusCode, 200);

      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect(body['known'], isTrue);
      expect(body['receivedChunks'], [0]);
      expect(body['fileComplete'], isFalse);
      expect(body['totalChunksExpected'], 3);
    });

    test('resume endpoint reports unknown for a transfer it never saw',
        () async {
      final res = await server.handler(
        Request('GET', url('/api/v1/transfer/resume/nope-tx/0')),
      );
      expect(res.statusCode, 200);

      final body = jsonDecode(await res.readAsString()) as Map<String, dynamic>;
      expect(body['known'], isFalse);
      expect(body['fileComplete'], isFalse);
      expect(body['receivedChunks'], isEmpty);
    });
  });
}
