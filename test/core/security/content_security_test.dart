import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/content_security.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_request.dart';

TransferRequest _request({
  List<TransferFile>? files,
  int? totalSize,
  int chunkSize = 1024,
}) {
  final resolved = files ??
      const <TransferFile>[
        TransferFile(
          name: 'photo.jpg',
          sizeInBytes: 4,
          mimeType: 'image/jpeg',
          localPath: '/photo.jpg',
        ),
      ];
  return TransferRequest(
    transferId: 'tx-1',
    senderId: 'device-a',
    senderName: 'Laptop',
    files: resolved,
    totalSizeBytes:
        totalSize ?? resolved.fold(0, (sum, file) => sum + file.sizeInBytes),
    timestamp: DateTime.now(),
    chunkSize: chunkSize,
  );
}

void main() {
  const validator = TransferContentValidator();

  group('TransferContentValidator', () {
    test('accepts a well-formed request', () {
      expect(validator.validate(_request()).isValid, isTrue);
    });

    test('rejects an empty file list and total mismatch', () {
      expect(
        validator.validate(_request(files: const [], totalSize: 0)).isValid,
        isFalse,
      );
      expect(validator.validate(_request(totalSize: 99)).isValid, isFalse);
    });

    test('rejects invalid sizes and chunk sizes', () {
      expect(
        validator
            .validate(
              _request(
                files: const [
                  TransferFile(
                    name: 'bad.bin',
                    sizeInBytes: -1,
                    mimeType: 'application/octet-stream',
                    localPath: '/bad.bin',
                  ),
                ],
                totalSize: -1,
              ),
            )
            .isValid,
        isFalse,
      );
      expect(validator.validate(_request(chunkSize: 0)).isValid, isFalse);
    });

    test('rejects malformed checksums and warns about executables', () {
      final malformed = validator.validate(
        _request(
          files: const [
            TransferFile(
              name: 'app.exe',
              sizeInBytes: 4,
              mimeType: 'application/octet-stream',
              localPath: '/app.exe',
              sha256: 'not-a-hash',
            ),
          ],
        ),
      );
      expect(malformed.isValid, isFalse);
      expect(malformed.errors.join(' '), contains('sha256'));

      final executable = validator.validate(
        _request(
          files: const [
            TransferFile(
              name: 'installer.exe',
              sizeInBytes: 4,
              mimeType: 'application/octet-stream',
              localPath: '/installer.exe',
            ),
          ],
        ),
      );
      expect(executable.isValid, isTrue);
      expect(executable.warnings, isNotEmpty);
    });
  });

  group('FileChecksum', () {
    test('computes a stable SHA-256 digest', () async {
      final dir = await Directory.systemTemp.createTemp('nearshare_hash_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}${Platform.pathSeparator}payload.txt');
      await file.writeAsString('NearShare');

      final first = await FileChecksum.sha256OfFile(file.path);
      final second = await FileChecksum.sha256OfBytes(
        await file.readAsBytes(),
      );
      expect(first, second);
      expect(first, hasLength(64));
    });
  });
}
