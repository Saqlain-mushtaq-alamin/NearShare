import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';

void main() {
  group('TransferProgress Domain Model Tests', () {
    test('Calculates percentage correctly', () {
      const progress1 = TransferProgress(
        transferId: 'tx-1',
        currentFileIndex: 0,
        totalFiles: 2,
        bytesTransferred: 50,
        totalBytes: 100,
        speedBps: 1024,
        status: TransferStatus.inProgress,
      );

      expect(progress1.percentage, 0.5);

      const zeroBytesProgress = TransferProgress(
        transferId: 'tx-2',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 0,
        speedBps: 0,
        status: TransferStatus.pending,
      );
      expect(zeroBytesProgress.percentage, 0.0);
    });

    test('Formats speeds correctly across units (B/s, KB/s, MB/s, GB/s)', () {
      const p1 = TransferProgress(
        transferId: '1',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 1000,
        speedBps: 500,
        status: TransferStatus.inProgress,
      );
      expect(p1.speedFormatted, '500 B/s');

      const p2 = TransferProgress(
        transferId: '2',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 1000,
        speedBps: 1024 * 50,
        status: TransferStatus.inProgress,
      );
      expect(p2.speedFormatted, '50.0 KB/s');

      const p3 = TransferProgress(
        transferId: '3',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 1000,
        speedBps: 1024 * 1024 * 3.5,
        status: TransferStatus.inProgress,
      );
      expect(p3.speedFormatted, '3.5 MB/s');

      const p4 = TransferProgress(
        transferId: '4',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 1000,
        speedBps: 1024 * 1024 * 1024 * 1.25,
        status: TransferStatus.inProgress,
      );
      expect(p4.speedFormatted, '1.25 GB/s');
    });

    test('Formats ETA correctly for remaining duration', () {
      // 10 MB total, 5 MB transferred, 1 MB/s speed -> 5 seconds remaining
      const p = TransferProgress(
        transferId: 'tx-eta',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 5 * 1024 * 1024,
        totalBytes: 10 * 1024 * 1024,
        speedBps: 1024 * 1024,
        status: TransferStatus.inProgress,
      );

      expect(p.etaFormatted, '00:05');

      const completedP = TransferProgress(
        transferId: 'tx-done',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 100,
        totalBytes: 100,
        speedBps: 100,
        status: TransferStatus.completed,
      );
      expect(completedP.etaFormatted, '00:00');

      const idleP = TransferProgress(
        transferId: 'tx-idle',
        currentFileIndex: 0,
        totalFiles: 1,
        bytesTransferred: 0,
        totalBytes: 100,
        speedBps: 0,
        status: TransferStatus.pending,
      );
      expect(idleP.etaFormatted, '--:--');
    });

    test('Serialization and Deserialization', () {
      const p = TransferProgress(
        transferId: 'tx-serial',
        currentFileIndex: 2,
        totalFiles: 5,
        bytesTransferred: 2048,
        totalBytes: 8192,
        speedBps: 1024.5,
        status: TransferStatus.inProgress,
        currentFileName: 'video.mp4',
        errorMessage: null,
      );

      final json = p.toJson();
      final restored = TransferProgress.fromJson(json);

      expect(restored.transferId, 'tx-serial');
      expect(restored.currentFileIndex, 2);
      expect(restored.totalFiles, 5);
      expect(restored.bytesTransferred, 2048);
      expect(restored.totalBytes, 8192);
      expect(restored.status, TransferStatus.inProgress);
      expect(restored.currentFileName, 'video.mp4');
    });
  });
}
