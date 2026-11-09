import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/network_security.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('TransferServer security', () {
    late Directory tempDir;
    late TransferServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearshare_security_');
    });

    tearDown(() async {
      await server.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Uri url(String path) => Uri.parse('http://localhost:53317$path');

    TransferRequest request({
      String senderId = 'sender-device',
      String? sha256,
    }) {
      return TransferRequest(
        transferId: 'security-tx',
        senderId: senderId,
        senderName: 'Sender',
        files: <TransferFile>[
          TransferFile(
            name: 'payload.txt',
            sizeInBytes: 5,
            mimeType: 'text/plain',
            localPath: '/payload.txt',
            sha256: sha256,
          ),
        ],
        totalSizeBytes: 5,
        timestamp: DateTime.now(),
        chunkSize: 5,
      );
    }

    Future<void> acceptNext(TransferServer target) async {
      target.onIncomingRequest.listen((incoming) {
        target.respondToRequest(incoming.transferId, true);
      });
    }

    Future<Response> prepare(TransferRequest value) {
      return Future<Response>.sync(
        () => server.handler(
          Request(
            'POST',
            url('/api/v1/transfer/prepare'),
            body: jsonEncode(value.toJson()),
            headers: const {'content-type': 'application/json'},
          ),
        ),
      );
    }

    Future<Response> uploadChunk() {
      return Future<Response>.value(
        server.handler(
          Request(
            'POST',
            url('/api/v1/transfer/chunk/security-tx/0'),
            body: Stream<List<int>>.value(utf8.encode('hello')),
            headers: const {
              'x-chunk-index': '0',
              'x-chunk-size': '5',
              'x-total-chunks': '1',
              'content-range': 'bytes 0-4/5',
            },
          ),
        ),
      );
    }

    Future<Response> finalize() {
      return Future<Response>.sync(
        () => server.handler(
          Request('POST', url('/api/v1/transfer/finalize/security-tx/0')),
        ),
      );
    }

    Future<bool> payloadExists() async {
      final entities = await tempDir.list(recursive: true).toList();
      return entities
          .whereType<File>()
          .any((file) => file.path.endsWith('payload.txt'));
    }

    test('blocks a public peer when security config is enabled', () async {
      server = TransferServer(
        storageService: FileStorageService(customDownloadPath: tempDir.path),
        securityConfig: const ServerSecurityConfig(),
        remoteAddressOverride: (_) => InternetAddress('8.8.8.8'),
      );

      expect((await prepare(request())).statusCode, 403);
    });

    test('rejects sending a transfer to the same device', () async {
      server = TransferServer(
        storageService: FileStorageService(customDownloadPath: tempDir.path),
        localDeviceIdProvider: () async => 'sender-device',
      );

      expect((await prepare(request())).statusCode, 409);
    });

    test('rejects a file whose checksum does not match', () async {
      server = TransferServer(
        storageService: FileStorageService(customDownloadPath: tempDir.path),
      );
      await acceptNext(server);

      expect((await prepare(request(sha256: '0' * 64))).statusCode, 200);
      expect((await uploadChunk()).statusCode, 200);
      expect((await finalize()).statusCode, 422);
      expect(await payloadExists(), isFalse);
    });

    test('accepts a matching checksum', () async {
      server = TransferServer(
        storageService: FileStorageService(customDownloadPath: tempDir.path),
      );
      await acceptNext(server);

      final digest = sha256.convert(utf8.encode('hello')).toString();
      expect((await prepare(request(sha256: digest))).statusCode, 200);
      expect((await uploadChunk()).statusCode, 200);
      expect((await finalize()).statusCode, 200);
      expect(await payloadExists(), isTrue);
    });
  });
}
