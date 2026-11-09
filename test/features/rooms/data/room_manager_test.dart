import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/data/room_manager.dart';
import 'package:nearshare/features/rooms/domain/room.dart';
import 'package:nearshare/features/rooms/domain/room_event.dart';
import 'package:nearshare/features/rooms/domain/room_member.dart';

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

RoomManager _managerWithRoom({String code = '123456'}) {
  final manager = RoomManager();
  manager.createRoom(
    hostDeviceId: 'host-1',
    hostDeviceName: 'Host',
    hostIpAddress: '192.168.1.5',
    hostPort: 8080,
    roomCode: code,
  );
  return manager;
}

void main() {
  group('RoomManager', () {
    late RoomManager manager;

    tearDown(() async {
      await manager.dispose();
    });

    test('createRoom produces a valid room and starts the lifecycle', () {
      manager = RoomManager();
      final room = manager.createRoom(
        hostDeviceId: 'host-1',
        hostDeviceName: 'Host',
        hostIpAddress: '192.168.1.5',
        hostPort: 8080,
      );

      expect(room.roomId, isNotEmpty);
      expect(RegExp(r'^\d{6}$').hasMatch(room.roomCode), isTrue);
      expect(room.status, RoomStatus.waiting);
      expect(manager.currentRoom, room);
      expect(manager.hasActiveRoom, isTrue);
    });

    test('accepts a join request with the correct code', () {
      manager = _managerWithRoom();

      final result = manager.handleJoinRequest(
        roomCode: '123456',
        member: _member('a'),
      );

      expect(result.accepted, isTrue);
      expect(result.room!.memberCount, 1);
      expect(manager.currentRoom!.memberById('a')?.deviceName, 'Device a');
    });

    test('rejects a join request with the wrong code', () {
      manager = _managerWithRoom();

      final result = manager.handleJoinRequest(
        roomCode: '000000',
        member: _member('a'),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, JoinRejectionReason.invalidCode);
      expect(manager.currentRoom!.memberCount, 0);
    });

    test('rejects join requests when the room is full', () {
      manager = _managerWithRoom();
      for (var i = 0; i < Room.maxMembers; i++) {
        final result = manager.handleJoinRequest(
          roomCode: '123456',
          member: _member('m$i'),
        );
        expect(result.accepted, isTrue);
      }

      final overflow = manager.handleJoinRequest(
        roomCode: '123456',
        member: _member('overflow'),
      );

      expect(overflow.accepted, isFalse);
      expect(overflow.reason, JoinRejectionReason.roomFull);
      expect(manager.currentRoom!.memberCount, Room.maxMembers);
    });

    test('removes a member and emits memberLeft', () async {
      manager = _managerWithRoom();
      manager.handleJoinRequest(roomCode: '123456', member: _member('a'));

      final events = <RoomEvent>[];
      final sub = manager.events.listen(events.add);
      addTearDown(sub.cancel);

      expect(manager.leaveRoom('a'), isTrue);
      await pumpEventQueue();

      expect(manager.currentRoom!.memberCount, 0);
      expect(events.single.type, RoomEventType.memberLeft);
      expect(events.single.data['deviceId'], 'a');
      expect(manager.leaveRoom('missing'), isFalse);
    });

    test('closing a room notifies every member', () async {
      manager = _managerWithRoom();
      manager.handleJoinRequest(roomCode: '123456', member: _member('a'));
      manager.handleJoinRequest(roomCode: '123456', member: _member('b'));

      final events = <RoomEvent>[];
      final sub = manager.events.listen(events.add);
      addTearDown(sub.cancel);

      await manager.closeRoom();
      await pumpEventQueue();

      expect(manager.currentRoom!.status, RoomStatus.closed);
      final closed = events.singleWhere(
        (event) => event.type == RoomEventType.roomClosed,
      );
      expect(closed.data['memberIds'], containsAll(['a', 'b']));

      final lateJoin = manager.handleJoinRequest(
        roomCode: '123456',
        member: _member('c'),
      );
      expect(lateJoin.accepted, isFalse);
      expect(lateJoin.reason, JoinRejectionReason.roomClosed);
    });

    test('marks a member as disconnected', () {
      manager = _managerWithRoom();
      manager.handleJoinRequest(roomCode: '123456', member: _member('a'));

      expect(manager.markMemberDisconnected('a'), isTrue);
      expect(
        manager.currentRoom!.memberById('a')?.status,
        RoomMemberStatus.disconnected,
      );
    });

    test('rejects creating a second room or an invalid supplied code', () {
      manager = _managerWithRoom();

      expect(
        () => manager.createRoom(
          hostDeviceId: 'host-2',
          hostDeviceName: 'Host 2',
          hostIpAddress: '10.0.0.1',
          hostPort: 9000,
        ),
        throwsStateError,
      );

      final other = RoomManager();
      addTearDown(other.dispose);
      expect(
        () => other.createRoom(
          hostDeviceId: 'host-2',
          hostDeviceName: 'Host 2',
          hostIpAddress: '10.0.0.1',
          hostPort: 9000,
          roomCode: '12ab',
        ),
        throwsArgumentError,
      );
    });
  });
}
