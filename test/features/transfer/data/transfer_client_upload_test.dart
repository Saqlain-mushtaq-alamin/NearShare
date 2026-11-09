import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TransferClient Chunk Upload Tests', () {
    late Directory clientTempDir;
    late Directory serverTempDir;
    late TransferServer server;
    late TransferClient client;
    late Device targetDevice;

    setUp(() async {
      clientTempDir =
          await Directory.systemTemp.createTemp('nearshare_client_temp_');
      serverTempDir =
          await Directory.systemTemp.createTemp('nearshare_server_temp_');

      final serverStorage =
          FileStorageService(customDownloadPath: serverTempDir.path);
      server = TransferServer(storageService: serverStorage);
      final port = await server.start(port: 0);

      client = TransferClient();
      targetDevice = Device(
        id: 'target-server',
        name: 'Receiver Phone',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await server.dispose();
      if (await clientTempDir.exists()) {
        await clientTempDir.delete(recursive: true);
      }
      if (await serverTempDir.exists()) {
        await serverTempDir.delete(recursive: true);
      }
    });

    Future<({TransferFile file, String content})> writeLocalFile(
      String name, {
      required int size,
      int seed = 65,
    }) async {
      final content = String.fromCharCodes(
        List.generate(size, (i) => seed + (i % 26)),
      );
      final localFile = File(p.join(clientTempDir.path, name));
      await localFile.writeAsString(content);
      return (
        file: TransferFile(
          name: name,
          sizeInBytes: await localFile.length(),
          mimeType: 'text/plain',
          localPath: localFile.path,
        ),
        content: content,
      );
    }

    Future<Uint8ListHolder> uploadAllChunks({
      required TransferFile file,
      required String transferId,
      required int chunkSize,
    }) async {
      final totalChunks = (file.sizeInBytes / chunkSize).ceil();
      var progressReported = false;

      for (var chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
        final start = chunkIndex * chunkSize;
        final endExclusive =
            (start + chunkSize).clamp(0, file.sizeInBytes).toInt();
        final bytes = await TransferClient.readChunk(
          file.localPath,
          start,
          endExclusive,
        );

        await client.uploadChunk(
          target: targetDevice,
          transferId: transferId,
          fileIndex: 0,
          chunkIndex: chunkIndex,
          bytes: bytes,
          startByte: start,
          endByte: endExclusive - 1,
          fileSize: file.sizeInBytes,
          totalChunks: totalChunks,
          onProgress: (sent, total) {
            if (sent > 0) progressReported = true;
          },
        );
      }

      return Uint8ListHolder(progressReported);
    }

    test(
        'uploads every chunk with progress reporting and assembles the file',
        () async {
      const contentSize = 2500;
      const chunkSize = 1024;
      final written = await writeLocalFile('upload_me.txt', size: contentSize);

      final request = TransferRequest(
        transferId: 'client-upload-tx-1',
        senderId: 'client-id',
        senderName: 'Sender Device',
        files: [written.file],
        totalSizeBytes: written.file.sizeInBytes,
        timestamp: DateTime.now(),
        chunkSize: chunkSize,
      );

      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      final prepared = await client.prepareTransfer(targetDevice, request);
      expect(prepared, isTrue);

      final upload = await uploadAllChunks(
        file: written.file,
        transferId: 'client-upload-tx-1',
        chunkSize: chunkSize,
      );
      expect(upload.progressReported, isTrue);

      final result = await client.finalizeFile(targetDevice, 'client-upload-tx-1', 0);
      expect(result['status'], 'completed');

      final savedPath = result['savePath'] as String;
      final savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsString(), written.content);
    });

    test('resume state reports received chunks so a resend can skip them',
        () async {
      const contentSize = 2500;
      const chunkSize = 1024;
      final written = await writeLocalFile('resume_me.txt', size: contentSize);

      final request = TransferRequest(
        transferId: 'client-upload-tx-2',
        senderId: 'client-id',
        senderName: 'Sender Device',
        files: [written.file],
        totalSizeBytes: written.file.sizeInBytes,
        timestamp: DateTime.now(),
        chunkSize: chunkSize,
      );

      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      await client.prepareTransfer(targetDevice, request);

      final first = await TransferClient.readChunk(written.file.localPath, 0, 1024);
      await client.uploadChunk(
        target: targetDevice,
        transferId: 'client-upload-tx-2',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: first,
        startByte: 0,
        endByte: 1023,
        fileSize: written.file.sizeInBytes,
        totalChunks: 3,
      );

      final resume = await client.getResumeState(targetDevice, 'client-upload-tx-2', 0);
      expect(resume.known, isTrue);
      expect(resume.receivedChunks, [0]);
      expect(resume.fileComplete, isFalse);

      for (var chunkIndex = 1; chunkIndex < 3; chunkIndex++) {
        final start = chunkIndex * chunkSize;
        final endExclusive = (start + chunkSize).clamp(0, written.file.sizeInBytes).toInt();
        final bytes = await TransferClient.readChunk(
          written.file.localPath,
          start,
          endExclusive,
        );
        await client.uploadChunk(
          target: targetDevice,
          transferId: 'client-upload-tx-2',
          fileIndex: 0,
          chunkIndex: chunkIndex,
          bytes: bytes,
          startByte: start,
          endByte: endExclusive - 1,
          fileSize: written.file.sizeInBytes,
          totalChunks: 3,
        );
      }

      final after = await client.getResumeState(targetDevice, 'client-upload-tx-2', 0);
      expect(after.receivedChunks, [0, 1, 2]);

      final result = await client.finalizeFile(targetDevice, 'client-upload-tx-2', 0);
      final savedFile = File(result['savePath'] as String);
      expect(await savedFile.readAsString(), written.content);

      final finalized = await client.getResumeState(targetDevice, 'client-upload-tx-2', 0);
      expect(finalized.fileComplete, isTrue);
    });

    test('finalize of an incomplete file reports the missing chunk indexes',
        () async {
      const contentSize = 2048;
      const chunkSize = 1024;
      final written = await writeLocalFile('incomplete.txt', size: contentSize);

      final request = TransferRequest(
        transferId: 'client-upload-tx-3',
        senderId: 'client-id',
        senderName: 'Sender Device',
        files: [written.file],
        totalSizeBytes: written.file.sizeInBytes,
        timestamp: DateTime.now(),
        chunkSize: chunkSize,
      );

      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      await client.prepareTransfer(targetDevice, request);

      final first = await TransferClient.readChunk(written.file.localPath, 0, 1024);
      await client.uploadChunk(
        target: targetDevice,
        transferId: 'client-upload-tx-3',
        fileIndex: 0,
        chunkIndex: 0,
        bytes: first,
        startByte: 0,
        endByte: 1023,
        fileSize: written.file.sizeInBytes,
        totalChunks: 2,
      );

      try {
        await client.finalizeFile(targetDevice, 'client-upload-tx-3', 0);
        fail('finalize should throw for an incomplete file');
      } on TransferClientException catch (e) {
        expect(e.statusCode, 409);
        expect(e.missingChunks, [1]);
      }
    });

    test('zero byte file finalizes into an empty file', () async {
      final localFile = File(p.join(clientTempDir.path, 'empty.bin'));
      await localFile.writeAsBytes(const []);
      final transferFile = TransferFile(
        name: 'empty.bin',
        sizeInBytes: 0,
        mimeType: 'application/octet-stream',
        localPath: localFile.path,
      );

      final request = TransferRequest(
        transferId: 'client-upload-tx-4',
        senderId: 'client-id',
        senderName: 'Sender Device',
        files: [transferFile],
        totalSizeBytes: 0,
        timestamp: DateTime.now(),
      );

      server.onIncomingRequest.listen((req) {
        server.respondToRequest(req.transferId, true);
      });

      await client.prepareTransfer(targetDevice, request);

      final resume = await client.getResumeState(targetDevice, 'client-upload-tx-4', 0);
      expect(resume.known, isTrue);
      expect(resume.receivedChunks, isEmpty);
      expect(resume.fileComplete, isFalse);

      final result = await client.finalizeFile(targetDevice, 'client-upload-tx-4', 0);
      final savedFile = File(result['savePath'] as String);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.length(), 0);

      final finalized = await client.getResumeState(targetDevice, 'client-upload-tx-4', 0);
      expect(finalized.fileComplete, isTrue);
    });
  });
}

class Uint8ListHolder {
  Uint8ListHolder(this.progressReported);
  final bool progressReported;
}
