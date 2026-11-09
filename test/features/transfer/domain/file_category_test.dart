import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/file_category.dart';

void main() {
  group('categorizeFile', () {
    test('assigns categories from mime types', () {
      expect(
        categorizeFile(name: 'a', mimeType: 'image/jpeg'),
        FileCategory.photos,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'video/mp4'),
        FileCategory.videos,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'application/pdf'),
        FileCategory.documents,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'text/plain'),
        FileCategory.documents,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'audio/mpeg'),
        FileCategory.documents,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'application/octet-stream'),
        FileCategory.other,
      );
    });

    test('falls back to the file extension when mime is missing', () {
      expect(
        categorizeFile(name: 'holiday.PNG'),
        FileCategory.photos,
      );
      expect(
        categorizeFile(name: 'clip.mov'),
        FileCategory.videos,
      );
      expect(
        categorizeFile(name: 'report.docx'),
        FileCategory.documents,
      );
      expect(
        categorizeFile(name: 'notes'),
        FileCategory.other,
      );
    });

    test('archives and unknown types land in other (shown under Documents tab)',
        () {
      expect(
        categorizeFile(name: 'backup.zip', mimeType: 'application/zip'),
        FileCategory.other,
      );
      expect(
        categorizeFile(name: 'payload.xyz'),
        FileCategory.other,
      );
    });

    test('is case-insensitive', () {
      expect(
        categorizeFile(name: 'PHOTO.JPEG'),
        FileCategory.photos,
      );
      expect(
        categorizeFile(name: 'a', mimeType: 'IMAGE/PNG'),
        FileCategory.photos,
      );
    });
  });
}
