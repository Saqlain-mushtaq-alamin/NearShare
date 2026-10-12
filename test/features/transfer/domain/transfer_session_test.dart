import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';

void main() {
  group('chunk math helpers', () {
    test('totalChunksForSize rounds up and handles empty files', () {
      expect(totalChunksForSize(0, 1024), 0);
      expect(totalChunksForSize(1, 1024), 1);
      expect(totalChunksForSize(1024, 1024), 1);
      expect(totalChunksForSize(1025, 1024), 2);
      expect(totalChunksForSize(2500, 1024), 3);
    });

    test('totalChunksForSize rejects a non-positive chunk size', () {
      expect(totalChunksForSize(100, 0), 0);
      expect(totalChunksForSize(100, -1), 0);
    });

    test('chunkRangesForSize covers every byte exactly once', () {
      final ranges = chunkRangesForSize(2500, 1024);
      expect(ranges.length, 3);
      expect(ranges.first.startByte, 0);
      expect(ranges.last.endByte, 2499);
      expect(ranges.fold<int>(0, (sum, c) => sum + c.size), 2500);

      var cursor = 0;
      for (final chunk in ranges) {
        expect(chunk.startByte, cursor);
        expect(chunk.endByteExclusive, cursor + chunk.size);
        cursor = chunk.endByteExclusive;
      }
    });

    test('chunkRangesForSize returns nothing for an empty file', () {
      expect(chunkRangesForSize(0, 1024), isEmpty);
    });
  });

  group('TransferSessionStatus', () {
    test('incomplete covers every non-terminal state', () {
      expect(TransferSessionStatus.pending.isIncomplete, isTrue);
      expect(TransferSessionStatus.inProgress.isIncomplete, isTrue);
      expect(TransferSessionStatus.paused.isIncomplete, isTrue);
      expect(TransferSessionStatus.completed.isIncomplete, isFalse);
      expect(TransferSessionStatus.failed.isIncomplete, isFalse);
      expect(TransferSessionStatus.cancelled.isIncomplete, isFalse);
    });

    test('fromName falls back to pending', () {
      expect(
        TransferSessionStatus.fromName('paused'),
        TransferSessionStatus.paused,
      );
      expect(
        TransferSessionStatus.fromName('nope'),
        TransferSessionStatus.pending,
      );
      expect(
        TransferSessionStatus.fromName(null),
        TransferSessionStatus.pending,
      );
    });
  });

  group('TransferSession', () {
    TransferSession build({
      Map<int, List<int>>? chunks,
      Map<int, String>? savePaths,
      TransferSessionStatus status = TransferSessionStatus.inProgress,
    }) {
      return TransferSession(
        transferId: 'session-1',
        peerId: 'peer-1',
        peerName: 'Peer Phone',
        peerIp: '192.168.1.7',
        peerPort: 53317,
        direction: TransferDirection.sending,
        status: status,
        files: const [
          TransferFile(
            name: 'a.bin',
            sizeInBytes: 2500,
            mimeType: 'application/octet-stream',
            localPath: '/a.bin',
          ),
        ],
        chunkSize: 1024,
        startedAt: DateTime.utc(2026, 1, 1),
        receivedChunksPerFile: chunks ?? const {},
        fileSavePaths: savePaths ?? const {},
      );
    }

    test('totalChunksForFile uses the session chunk size', () {
      expect(build().totalChunksForFile(0), 3);
      expect(build().totalChunksForFile(5), 0);
    });

    test('receivedChunksForFile is always sorted ascending', () {
      final session = build(chunks: {0: [2, 0, 1]});
      expect(session.receivedChunksForFile(0), [0, 1, 2]);
    });

    test('missingChunksForFile lists only what is left', () {
      expect(build().missingChunksForFile(0), [0, 1, 2]);
      expect(build(chunks: {0: [0]}).missingChunksForFile(0), [1, 2]);
      expect(build(chunks: {0: [0, 1, 2]}).missingChunksForFile(0), isEmpty);
    });

    test('isFileComplete is true once a destination path is recorded', () {
      final session = build(savePaths: {0: '/somewhere/a.bin'});
      expect(session.isFileComplete(0), isTrue);
      expect(session.areAllFilesComplete, isTrue);
    });

    test('receivedByteCountForFile prefers the recorded destination', () {
      final session = build(savePaths: {0: '/somewhere/a.bin'});
      expect(session.receivedByteCountForFile(0), 2500);
    });

    test('progressFraction accounts for partially received chunks', () {
      final session = build(chunks: {0: [0]});
      expect(session.progressFraction, closeTo(1024 / 2500, 0.0001));
    });

    test('json round trip keeps chunk bookkeeping and save paths', () {
      final original = build(
        chunks: {0: [0, 2]},
        savePaths: {0: '/out/a.bin'},
        status: TransferSessionStatus.paused,
      );

      final restored = TransferSession.fromJson(original.toJson());

      expect(restored.transferId, original.transferId);
      expect(restored.status, TransferSessionStatus.paused);
      expect(restored.receivedChunksPerFile[0], [0, 2]);
      expect(restored.fileSavePaths[0], '/out/a.bin');
      expect(restored.files.single.name, 'a.bin');
      expect(restored.peerIp, '192.168.1.7');
    });

    test('copyWith with clearErrorMessage removes the failure text', () {
      final session = build().copyWith(errorMessage: 'boom');
      expect(session.errorMessage, 'boom');
      expect(session.copyWith(clearErrorMessage: true).errorMessage, isNull);
    });
  });
}
