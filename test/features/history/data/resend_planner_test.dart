import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/history/data/history_repository.dart';
import 'package:nearshare/features/history/data/resend_planner.dart';
import 'package:nearshare/features/history/domain/transfer_record.dart';

void main() {
  group('ResendPlanner', () {
    late Directory tempDir;
    late File presentFile;
    final planner = const ResendPlanner();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resend_planner_');
      presentFile = File('${tempDir.path}${Platform.pathSeparator}still-here.txt');
      await presentFile.writeAsString('payload');
    });

    tearDown(() async {
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

    test('classifies present files as available and missing ones as missing',
        () async {
      final gonePath =
          '${tempDir.path}${Platform.pathSeparator}already-gone.txt';

      final plan = await planner.buildPlan(
        recordWith([
          TransferFileRecord(
            fileName: 'still-here.txt',
            fileSizeBytes: await presentFile.length(),
            mimeType: 'text/plain',
            localPath: presentFile.path,
            status: TransferRecordStatus.completed,
          ),
          TransferFileRecord(
            fileName: 'already-gone.txt',
            fileSizeBytes: 9,
            mimeType: 'text/plain',
            localPath: gonePath,
            status: TransferRecordStatus.failed,
          ),
        ]),
      );

      expect(plan.availableFiles, hasLength(1));
      expect(plan.availableFiles.single.name, 'still-here.txt');
      expect(plan.availableFiles.single.localPath, presentFile.path);
      expect(plan.missingFiles, hasLength(1));
      expect(plan.missingFiles.single.fileName, 'already-gone.txt');
      expect(plan.allFilesAvailable, isFalse);
      expect(plan.isUnusable, isFalse);
    });

    test('treats a null or blank path as missing', () async {
      final plan = await planner.buildPlan(
        recordWith([
          const TransferFileRecord(
            fileName: 'unknown.txt',
            fileSizeBytes: 3,
            mimeType: 'text/plain',
            status: TransferRecordStatus.failed,
          ),
          const TransferFileRecord(
            fileName: 'blank.txt',
            fileSizeBytes: 3,
            mimeType: 'text/plain',
            localPath: '   ',
            status: TransferRecordStatus.failed,
          ),
        ]),
      );

      expect(plan.availableFiles, isEmpty);
      expect(plan.missingFiles, hasLength(2));
      expect(plan.isUnusable, isTrue);
    });

    test('a directory is not a usable resend source', () async {
      final plan = await planner.buildPlan(
        recordWith([
          TransferFileRecord(
            fileName: 'folder',
            fileSizeBytes: 0,
            mimeType: 'inode/directory',
            localPath: tempDir.path,
            status: TransferRecordStatus.completed,
          ),
        ]),
      );

      expect(plan.availableFiles, isEmpty);
      expect(plan.isUnusable, isTrue);
    });

    test('allFilesAvailable is true when nothing went missing', () async {
      final plan = await planner.buildPlan(
        recordWith([
          TransferFileRecord(
            fileName: 'still-here.txt',
            fileSizeBytes: await presentFile.length(),
            mimeType: 'text/plain',
            localPath: presentFile.path,
            status: TransferRecordStatus.completed,
          ),
        ]),
      );

      expect(plan.allFilesAvailable, isTrue);
      expect(plan.availableSizeBytes, await presentFile.length());
    });

    group('matchDevice', () {
      final laptop = Device(
        id: 'peer-1',
        name: 'Laptop',
        platform: 'windows',
        ipAddress: '192.168.1.5',
        port: 53317,
        discoveredAt: DateTime(2026, 1, 1),
      );
      final tablet = Device(
        id: 'peer-2',
        name: 'Tablet',
        platform: 'android',
        ipAddress: '192.168.1.6',
        port: 53318,
        discoveredAt: DateTime(2026, 1, 1),
      );

      test('prefers an exact device id match', () {
        final matched = planner.matchDevice(
          recordWith(const []),
          [tablet, laptop],
        );
        expect(matched?.id, 'peer-1');
      });

      test('falls back to a case-insensitive name match', () {
        final matched = planner.matchDevice(
          recordWith(const []).copyWith(peerDeviceId: 'unknown-id'),
          [tablet, laptop],
        );
        expect(matched?.name, 'Laptop');
      });

      test('returns null when the peer is not currently discovered', () {
        final matched = planner.matchDevice(
          recordWith(const []).copyWith(peerDeviceId: 'gone'),
          [tablet],
        );
        expect(matched, isNull);
      });

      test('returns null when there are no discovered devices', () {
        final matched = planner.matchDevice(recordWith(const []), const []);
        expect(matched, isNull);
      });
    });
  });
}
