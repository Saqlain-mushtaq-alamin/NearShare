import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_progress.dart';

void main() {
  group('TransferStatus Enum Tests', () {
    test('Contains all expected transfer states', () {
      expect(TransferStatus.values, contains(TransferStatus.pending));
      expect(TransferStatus.values, contains(TransferStatus.accepted));
      expect(TransferStatus.values, contains(TransferStatus.rejected));
      expect(TransferStatus.values, contains(TransferStatus.inProgress));
      expect(TransferStatus.values, contains(TransferStatus.completed));
      expect(TransferStatus.values, contains(TransferStatus.failed));
      expect(TransferStatus.values, contains(TransferStatus.cancelled));
      expect(TransferStatus.values.length, 7);
    });

    test('isFinished property correctly identifies terminal states', () {
      expect(TransferStatus.completed.isFinished, isTrue);
      expect(TransferStatus.failed.isFinished, isTrue);
      expect(TransferStatus.cancelled.isFinished, isTrue);
      expect(TransferStatus.rejected.isFinished, isTrue);

      expect(TransferStatus.pending.isFinished, isFalse);
      expect(TransferStatus.accepted.isFinished, isFalse);
      expect(TransferStatus.inProgress.isFinished, isFalse);
    });
  });
}
