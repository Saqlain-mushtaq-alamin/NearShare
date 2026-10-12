import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';

void main() {
  group('TransferFile Domain Model Tests', () {
    test('Constructs TransferFile with all required attributes', () {
      const file = TransferFile(
        name: 'document.pdf',
        sizeInBytes: 102400,
        mimeType: 'application/pdf',
        localPath: '/storage/docs/document.pdf',
        savePath: '/downloads/document.pdf',
      );

      expect(file.name, 'document.pdf');
      expect(file.sizeInBytes, 102400);
      expect(file.mimeType, 'application/pdf');
      expect(file.localPath, '/storage/docs/document.pdf');
      expect(file.savePath, '/downloads/document.pdf');
    });

    test('copyWith updates specified fields only', () {
      const original = TransferFile(
        name: 'photo.jpg',
        sizeInBytes: 2048,
        mimeType: 'image/jpeg',
        localPath: '/storage/photo.jpg',
      );

      final updated = original.copyWith(
        savePath: '/received/photo.jpg',
        sizeInBytes: 4096,
      );

      expect(updated.name, 'photo.jpg');
      expect(updated.sizeInBytes, 4096);
      expect(updated.mimeType, 'image/jpeg');
      expect(updated.localPath, '/storage/photo.jpg');
      expect(updated.savePath, '/received/photo.jpg');
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      const original = TransferFile(
        name: 'archive.zip',
        sizeInBytes: 5242880,
        mimeType: 'application/zip',
        localPath: '/tmp/archive.zip',
        savePath: '/dest/archive.zip',
      );

      final json = original.toJson();
      final restored = TransferFile.fromJson(json);

      expect(restored, equals(original));
      expect(restored.name, 'archive.zip');
      expect(restored.sizeInBytes, 5242880);
      expect(restored.mimeType, 'application/zip');
      expect(restored.localPath, '/tmp/archive.zip');
      expect(restored.savePath, '/dest/archive.zip');
    });

    test('Equality and hashCode match for identical instances', () {
      const file1 = TransferFile(
        name: 'music.mp3',
        sizeInBytes: 3000,
        mimeType: 'audio/mpeg',
        localPath: '/a/music.mp3',
      );
      const file2 = TransferFile(
        name: 'music.mp3',
        sizeInBytes: 3000,
        mimeType: 'audio/mpeg',
        localPath: '/a/music.mp3',
      );
      const file3 = TransferFile(
        name: 'music2.mp3',
        sizeInBytes: 3000,
        mimeType: 'audio/mpeg',
        localPath: '/a/music.mp3',
      );

      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
      expect(file1, isNot(equals(file3)));
    });
  });
}
