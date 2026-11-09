import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';
import 'package:nearshare/features/transfer/data/file_storage_service.dart';
import 'package:nearshare/features/transfer/data/transfer_client.dart';
import 'package:nearshare/features/transfer/data/transfer_manager.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TransferNotifier.startResend', () {
    late Directory tempDir;
    late TransferManager manager;
    late TransferNotifier notifier;
    late File presentFile;
    late File alsoPresent;

    final laptop = Device(
      id: 'peer-1',
      name: 'Laptop',
      platform: 'windows',
      ipAddress: '192.168.1.5',
      port: 53317,
      discoveredAt: DateTime.now(),
    );
    final tablet = Device(
      id: 'peer-2',
      name: 'Tablet',
      platform: 'android',
      ipAddress: '192.168.1.6',
      port: 53318,
      discoveredAt: DateTime.now(),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('resend_notifier_');
      presentFile = File('${tempDir.path}${Platform.pathSeparator}a.txt');
      await presentFile.writeAsString('aaaa');
      alsoPresent = File('${tempDir.path}${Platform.pathSeparator}b.txt');
      await alsoPresent.writeAsString('bbbbbb');

      manager = TransferManager(
        client: TransferClient(),
        storageService: FileStorageService(customDownloadPath: tempDir.path),
        sessionRepository: InMemoryTransferSessionRepository(),
      );
      final identity = DeviceIdentityService(
        prefs: await SharedPreferences.getInstance(),
      );
      notifier = TransferNotifier(manager, identity);
    });

    tearDown(() async {
      notifier.dispose();
      await manager.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    TransferRecord recordWith(List<TransferFileRecord> files) {
      return TransferRecord(
        transferId: 'resend-1',
        direction: TransferDirection.sending,
        peerDeviceId: 'peer-1',
        peerDeviceName: 'Laptop',
        totalFiles: files.length,
        totalSizeBytes: files.fold(0, (sum, f) => sum + f.fileSizeBytes),
        status: TransferRecordStatus.failed,
        timestamp: DateTime(2026, 1, 1),
        files: files,
      );
    }

    test('pre-attaches surviving files and pre-selects the discovered peer',
        () async {
      final record = recordWith([
        TransferFileRecord(
          fileName: 'a.txt',
          fileSizeBytes: 4,
          mimeType: 'text/plain',
          localPath: presentFile.path,
          status: TransferRecordStatus.completed,
        ),
        TransferFileRecord(
          fileName: 'b.txt',
          fileSizeBytes: 6,
          mimeType: 'text/plain',
          localPath: alsoPresent.path,
          status: TransferRecordStatus.completed,
        ),
      ]);

      final outcome = await notifier.startResend(
        record,
        availableDevices: [tablet, laptop],
      );

      expect(outcome.canSend, isTrue);
      expect(outcome.hasMissingFiles, isFalse);
      expect(outcome.matchedDevice?.id, 'peer-1');

      final state = notifier.state;
      expect(state.selectedFiles, hasLength(2));
      expect(state.selectedFiles.map((f) => f.name), ['a.txt', 'b.txt']);
      expect(state.selectedFiles[0].localPath, presentFile.path);
      expect(state.selectedTargetDevice?.id, 'peer-1');
    });

    test('keeps the surviving subset and reports the missing ones', () async {
      final record = recordWith([
        TransferFileRecord(
          fileName: 'a.txt',
          fileSizeBytes: 4,
          mimeType: 'text/plain',
          localPath: presentFile.path,
          status: TransferRecordStatus.completed,
        ),
        TransferFileRecord(
          fileName: 'deleted.txt',
          fileSizeBytes: 9,
          mimeType: 'text/plain',
          localPath: '${tempDir.path}${Platform.pathSeparator}deleted.txt',
          status: TransferRecordStatus.failed,
        ),
      ]);

      final outcome = await notifier.startResend(
        record,
        availableDevices: [laptop],
      );

      expect(outcome.canSend, isTrue);
      expect(outcome.hasMissingFiles, isTrue);
      expect(
        outcome.missingFilesMessage,
        'Some files are no longer available at their original locations.',
      );
      expect(outcome.plan.missingFiles.single.fileName, 'deleted.txt');

      final state = notifier.state;
      expect(state.selectedFiles, hasLength(1));
      expect(state.selectedFiles.single.name, 'a.txt');
    });

    test('reports unusable history and clears the send flow', () async {
      final record = recordWith([
        TransferFileRecord(
          fileName: 'gone.txt',
          fileSizeBytes: 9,
          mimeType: 'text/plain',
          localPath: '${tempDir.path}${Platform.pathSeparator}gone.txt',
          status: TransferRecordStatus.failed,
        ),
      ]);

      // Make sure a stale selection does not survive a failed resend.
      notifier.setSelectedFiles([
        const TransferFile(
          name: 'stale.txt',
          sizeInBytes: 1,
          mimeType: 'text/plain',
          localPath: '/stale.txt',
        ),
      ]);
      notifier.setSelectedTargetDevice(laptop);

      final outcome = await notifier.startResend(
        record,
        availableDevices: [laptop],
      );

      expect(outcome.canSend, isFalse);
      expect(notifier.state.selectedFiles, isEmpty);
      expect(notifier.state.selectedTargetDevice, isNull);
      expect(
        notifier.state.errorMessage,
        'Some files are no longer available at their original locations.',
      );
    });

    test('leaves the target unselected when the peer is not discovered',
        () async {
      final record = recordWith([
        TransferFileRecord(
          fileName: 'a.txt',
          fileSizeBytes: 4,
          mimeType: 'text/plain',
          localPath: presentFile.path,
          status: TransferRecordStatus.completed,
        ),
      ]);

      final outcome = await notifier.startResend(
        record,
        availableDevices: [tablet],
      );

      expect(outcome.canSend, isTrue);
      expect(outcome.matchedDevice, isNull);
      expect(notifier.state.selectedTargetDevice, isNull);
      expect(notifier.state.selectedFiles, hasLength(1));
    });

    test('clears the previous progress before starting a resend', () async {
      final record = recordWith([
        TransferFileRecord(
          fileName: 'a.txt',
          fileSizeBytes: 4,
          mimeType: 'text/plain',
          localPath: presentFile.path,
          status: TransferRecordStatus.completed,
        ),
      ]);

      await notifier.startResend(record, availableDevices: [laptop]);

      expect(notifier.state.activeProgress, isNull);
      expect(notifier.state.activeSession, isNull);
      expect(notifier.state.errorMessage, isNull);
    });
  });
}
