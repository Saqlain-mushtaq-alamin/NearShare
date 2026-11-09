import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/network_security.dart';
import 'package:nearshare/core/security/tls_identity.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_server.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

void main() {
  test('transfer server requires and validates pinned TLS certificates',
      () async {
    final identity = TlsIdentityService(keySize: 2048).generate(
      commonName: 'TLS Integration Test',
    );
    final server = TransferServer(
      securityConfig: const ServerSecurityConfig(),
      tlsIdentityProvider: () async => identity,
    );
    addTearDown(server.dispose);
    server.onIncomingRequest.listen((incoming) {
      server.respondToRequest(incoming.transferId, true);
    });

    final port = await server.start(port: 0);
    final client = TransferClient();

    TransferRequest request(String id) {
      return TransferRequest(
        transferId: id,
        senderId: 'tls-sender',
        senderName: 'Sender',
        files: <TransferFile>[
          TransferFile(
            name: 'tls.txt',
            sizeInBytes: 0,
            mimeType: 'text/plain',
            localPath: '/tls.txt',
          ),
        ],
        totalSizeBytes: 0,
        timestamp: DateTime.now(),
        chunkSize: 1,
      );
    }

    Device target(String? fingerprint) {
      return Device(
        id: 'tls-receiver',
        name: 'Receiver',
        platform: 'linux',
        ipAddress: '127.0.0.1',
        port: port,
        discoveredAt: DateTime.now(),
        certFingerprint: fingerprint,
      );
    }

    await expectLater(
      client.prepareTransfer(
        target('0' * 64),
        request('wrong-pin'),
      ),
      throwsA(isA<DioException>()),
    );

    expect(
      await client.prepareTransfer(
        target(identity.fingerprint),
        request('correct-pin'),
      ),
      isTrue,
    );
  });
}
