import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileStorageService Tests', () {
    late Directory tempDir;
    late FileStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nearshare_test_');
      storageService = FileStorageService(customDownloadPath: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('sanitizeFileName removes path traversals and illegal characters', () {
      expect(
        storageService.sanitizeFileName('../../malicious:file<name>?.pdf'),
        'malicious_file_name__.pdf',
      );
      expect(
        storageService.sanitizeFileName('C:\\Windows\\System32\\cmd.exe'),
        'cmd.exe',
      );
      expect(
        storageService.sanitizeFileName('   '),
        'downloaded_file',
      );
    });

    test('prepareDestinationFile creates unique deduplicated filenames',
        () async {
      final file1 = await storageService.prepareDestinationFile('document.pdf');
      expect(p.basename(file1.path), 'document.pdf');
      await file1.writeAsString('file 1 content');

      // Second file with same name
      final file2 = await storageService.prepareDestinationFile('document.pdf');
      expect(p.basename(file2.path), 'document (1).pdf');
      await file2.writeAsString('file 2 content');

      // Third file with same name
      final file3 = await storageService.prepareDestinationFile('document.pdf');
      expect(p.basename(file3.path), 'document (2).pdf');
    });

    test('preserves unicode and emoji file names', () {
      const name = '😀 vacation – 日本.png';
      expect(storageService.sanitizeFileName(name), name);
    });

    test('truncates long names without splitting emoji or extension', () {
      final name = '${'😀' * 150}.webp';
      final sanitized = storageService.sanitizeFileName(name);

      expect(
        sanitized.length,
        lessThanOrEqualTo(FileStorageService.maxFileNameLength),
      );
      expect(sanitized, endsWith('.webp'));
      expect(sanitized.runes.every((rune) => rune != 0xFFFD), isTrue);
      final highSurrogates = sanitized.codeUnits
          .where((unit) => unit >= 0xD800 && unit <= 0xDBFF)
          .length;
      final lowSurrogates = sanitized.codeUnits
          .where((unit) => unit >= 0xDC00 && unit <= 0xDFFF)
          .length;
      expect(highSurrogates, lowSurrogates);
    });

    test('prefixes Windows reserved device names', () {
      expect(storageService.sanitizeFileName('CON.txt'), '_CON.txt');
      expect(storageService.sanitizeFileName('lpt9.log'), '_lpt9.log');
    });

    test('prepareDestinationFile supports zero-byte files', () async {
      final file = await storageService.prepareDestinationFile('empty.bin');
      await file.writeAsBytes(const <int>[]);
      expect(await file.exists(), isTrue);
      expect(await file.length(), 0);
    });

    test('deleteIncompleteFile removes file when present', () async {
      final file = File(p.join(tempDir.path, 'incomplete.tmp'));
      await file.writeAsString('partial data');
      expect(await file.exists(), isTrue);

      await storageService.deleteIncompleteFile(file.path);
      expect(await file.exists(), isFalse);

      // Deleting non-existent file does not throw
      await storageService.deleteIncompleteFile('/non/existent/path.tmp');
    });
  });
}
