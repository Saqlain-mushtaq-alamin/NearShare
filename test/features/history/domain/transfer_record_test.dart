import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/history/domain/file_kind.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';

void main() {
  group('TransferRecord', () {
    TransferSession buildSession({
      Map<int, String> fileSavePaths = const {},
      List<TransferFile>? files,
    }) {
      return TransferSession(
        transferId: 'tr-1',
        peerId: 'peer-1',
        peerName: 'Laptop',
        direction: TransferDirection.sending,
        status: TransferSessionStatus.completed,
        files: files ??
            const [
              TransferFile(
                name: 'report.pdf',
                sizeInBytes: 2048,
                mimeType: 'application/pdf',
                localPath: '/tmp/report.pdf',
              ),
              TransferFile(
                name: 'photo.png',
                sizeInBytes: 4096,
                mimeType: 'image/png',
                localPath: '/tmp/photo.png',
              ),
            ],
        chunkSize: 1024,
        startedAt: DateTime(2026, 1, 1, 10),
        completedAt: DateTime(2026, 1, 1, 10, 5),
        fileSavePaths: fileSavePaths,
      );
    }

    test('fromSession maps a fully delivered session onto a completed record',
        () {
      final record = TransferRecord.fromSession(
        buildSession(fileSavePaths: {0: '/dl/report.pdf', 1: '/dl/photo.png'}),
        TransferRecordStatus.completed,
        completedAt: DateTime(2026, 1, 1, 10, 5),
      );

      expect(record.transferId, 'tr-1');
      expect(record.direction, TransferDirection.sending);
      expect(record.peerDeviceName, 'Laptop');
      expect(record.totalFiles, 2);
      expect(record.totalSizeBytes, 6144);
      expect(record.status, TransferRecordStatus.completed);
      expect(record.completedAt, DateTime(2026, 1, 1, 10, 5));
      expect(record.files, hasLength(2));
      expect(record.files.every((f) => f.isCompleted), isTrue);
      expect(record.completedFiles, hasLength(2));
    });

    test('fromSession marks files without a save path as failed', () {
      final record = TransferRecord.fromSession(
        buildSession(fileSavePaths: {0: '/dl/report.pdf'}),
        TransferRecordStatus.failed,
      );

      expect(record.status, TransferRecordStatus.failed);
      expect(record.files[0].status, TransferRecordStatus.completed);
      expect(record.files[1].status, TransferRecordStatus.failed);
      expect(record.completedFiles, hasLength(1));
    });

    test('fromSession points received files at their download destination', () {
      final session = buildSession(fileSavePaths: {0: '/downloads/report.pdf'})
          .copyWith(direction: TransferDirection.receiving);

      final record = TransferRecord.fromSession(
        session,
        TransferRecordStatus.completed,
      );

      expect(record.isReceived, isTrue);
      expect(record.isSent, isFalse);
      expect(record.directionLabel, 'Received');
      expect(record.files[0].localPath, '/downloads/report.pdf');
    });

    test('matchesSearch covers the peer name and file names, case-insensitively',
        () {
      final record = TransferRecord.fromSession(
        buildSession(),
        TransferRecordStatus.completed,
      );

      expect(record.matchesSearch('laptop'), isTrue);
      expect(record.matchesSearch('REPORT'), isTrue);
      expect(record.matchesSearch('missing.txt'), isFalse);
      expect(record.matchesSearch('   '), isTrue);
    });

    test('json round trip preserves every field', () {
      final original = TransferRecord.fromSession(
        buildSession(fileSavePaths: {0: '/dl/a', 1: '/dl/b'}),
        TransferRecordStatus.cancelled,
      );

      final restored = TransferRecord.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.files, original.files);
    });

    test('TransferRecordStatus.fromName falls back to failed on garbage', () {
      expect(
        TransferRecordStatus.fromName('completed'),
        TransferRecordStatus.completed,
      );
      expect(
        TransferRecordStatus.fromName('cancelled'),
        TransferRecordStatus.cancelled,
      );
      expect(TransferRecordStatus.fromName('nope'), TransferRecordStatus.failed);
      expect(TransferRecordStatus.fromName(null), TransferRecordStatus.failed);
    });
  });

  group('FileKind', () {
    test('classifies common extensions', () {
      expect(FileKind.fromFileName('a.jpg'), FileKind.image);
      expect(FileKind.fromFileName('b.MP4'), FileKind.video);
      expect(FileKind.fromFileName('c.flac'), FileKind.audio);
      expect(FileKind.fromFileName('d.tar.gz'), FileKind.archive);
      expect(FileKind.fromFileName('e.docx'), FileKind.document);
      expect(FileKind.fromFileName('f.bin'), FileKind.other);
      expect(FileKind.fromFileName('noext'), FileKind.other);
      expect(FileKind.fromExtension(''), FileKind.other);
    });

    test('only images and videos offer thumbnails', () {
      expect(FileKind.image.hasThumbnail, isTrue);
      expect(FileKind.video.hasThumbnail, isTrue);
      expect(FileKind.document.hasThumbnail, isFalse);
    });

    test('exposes the file extension used for display', () {
      final record = TransferFileRecord(
        fileName: 'holiday.photo.JPEG',
        fileSizeBytes: 10,
        mimeType: 'image/jpeg',
        status: TransferRecordStatus.completed,
      );
      expect(record.extension, 'jpeg');
      expect(FileKind.fromExtension(record.extension), FileKind.image);
    });
  });
}
