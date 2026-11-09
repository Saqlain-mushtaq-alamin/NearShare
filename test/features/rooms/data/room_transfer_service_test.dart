import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/rooms/data/room_transfer_service.dart';
import 'package:nearshare/features/rooms/domain/room_member.dart';
import 'package:nearshare/features/rooms/domain/room_transfer_progress.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';

RoomMember _member(String id, {RoomMemberStatus status = RoomMemberStatus.connected}) {
  return RoomMember(
    deviceId: id,
    deviceName: 'Device $id',
    platform: 'android',
    ipAddress: '192.168.1.20',
    port: 53317,
    joinedAt: DateTime(2026, 1, 1),
    status: status,
  );
}

final _localDevice = Device(
  id: 'host',
  name: 'Host',
  platform: 'android',
  ipAddress: '192.168.1.5',
  port: 53317,
  discoveredAt: DateTime(2026, 1, 1),
);

const _files = [
  TransferFile(
    name: 'a.txt',
    sizeInBytes: 100,
    mimeType: 'text/plain',
    localPath: '/a.txt',
  ),
  TransferFile(
    name: 'b.txt',
    sizeInBytes: 200,
    mimeType: 'text/plain',
    localPath: '/b.txt',
  ),
];

void main() {
  group('RoomTransferService', () {
    test('sends to all members in parallel', () async {
      final members = [_member('a'), _member('b'), _member('c')];
      final release = Completer<void>();
      var active = 0;
      var maxActive = 0;

      final service = RoomTransferService(
        sender: (member, files, local) async {
          active++;
          maxActive = max(maxActive, active);
          await release.future;
          active--;
        },
      );

      final future = service.sendToAll(
        members: members,
        files: _files,
        localDevice: _localDevice,
      );

      await Future<void>.delayed(Duration.zero);
      expect(maxActive, 3);
      release.complete();

      final summary = await future;
      expect(summary.completedCount, 3);
      expect(summary.failedCount, 0);
      expect(summary.allSucceeded, isTrue);
      expect(summary.overallPercentage, 1.0);

      await service.dispose();
    });

    test('contains a partial failure without stopping other members', () async {
      final members = [_member('a'), _member('b'), _member('c')];
      final service = RoomTransferService(
        sender: (member, files, local) async {
          if (member.deviceId == 'b') {
            throw StateError('boom');
          }
        },
      );

      final summary = await service.sendToAll(
        members: members,
        files: _files,
        localDevice: _localDevice,
      );

      expect(summary.completedCount, 2);
      expect(summary.failedCount, 1);
      expect(summary.hasFailures, isTrue);
      expect(summary.allSucceeded, isFalse);
      expect(summary.isFinished, isTrue);

      final failed = summary.members.firstWhere((m) => m.deviceId == 'b');
      expect(failed.status, RoomMemberTransferStatus.failed);
      expect(failed.errorMessage, contains('boom'));

      await service.dispose();
    });

    test('fails disconnected members without attempting a send', () async {
      final members = [
        _member('a'),
        _member('offline', status: RoomMemberStatus.disconnected),
      ];
      final attempted = <String>[];

      final service = RoomTransferService(
        sender: (member, files, local) async => attempted.add(member.deviceId),
      );

      final summary = await service.sendToAll(
        members: members,
        files: _files,
        localDevice: _localDevice,
      );

      expect(attempted, ['a']);
      expect(summary.completedCount, 1);
      expect(summary.failedCount, 1);
      expect(
        summary.members.firstWhere((m) => m.deviceId == 'offline').errorMessage,
        'Device disconnected',
      );

      await service.dispose();
    });

    test('emits progress snapshots while sending', () async {
      final service = RoomTransferService(
        sender: (member, files, local) async {},
      );
      final snapshots = <RoomTransferSummary>[];
      final sub = service.onProgress.listen(snapshots.add);
      addTearDown(sub.cancel);

      await service.sendToAll(
        members: [_member('a')],
        files: _files,
        localDevice: _localDevice,
      );
      await pumpEventQueue();

      expect(snapshots, isNotEmpty);
      expect(snapshots.last.completedCount, 1);

      await service.dispose();
    });
  });
}
