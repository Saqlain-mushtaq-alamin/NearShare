import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/domain/room.dart';
import 'package:nearshare/features/rooms/domain/room_member.dart';

RoomMember _member(String id, {RoomMemberStatus status = RoomMemberStatus.connected}) {
  return RoomMember(
    deviceId: id,
    deviceName: 'Device $id',
    platform: 'android',
    ipAddress: '192.168.1.10',
    port: 53317,
    joinedAt: DateTime(2026, 1, 1),
    status: status,
  );
}

Room _room({List<RoomMember> members = const []}) {
  return Room(
    roomId: 'room-1',
    roomCode: '123456',
    hostDeviceId: 'host-1',
    hostDeviceName: 'Host Device',
    hostIpAddress: '192.168.1.5',
    hostPort: 8080,
    members: members,
    status: RoomStatus.waiting,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('Room', () {
    test('adds, replaces and removes members', () {
      final room = _room();
      final updated = room.addMember(_member('a'));
      expect(updated.memberCount, 1);
      expect(updated.memberById('a')?.deviceName, 'Device a');

      final replaced = updated.addMember(_member('a', status: RoomMemberStatus.disconnected));
      expect(replaced.memberCount, 1);
      expect(replaced.memberById('a')?.status, RoomMemberStatus.disconnected);

      final removed = replaced.removeMember('a');
      expect(removed.memberCount, 0);
      expect(removed.removeMember('missing'), same(removed));
    });

    test('is full at the maximum member capacity', () {
      var room = _room();
      for (var i = 0; i < Room.maxMembers; i++) {
        room = room.addMember(_member('m$i'));
      }
      expect(room.isFull, isTrue);
      expect(room.memberCount, Room.maxMembers);
      expect(() => room.addMember(_member('overflow')), throwsStateError);
    });

    test('serializes to and from JSON', () {
      final room = _room(members: [_member('a'), _member('b')])
          .copyWith(status: RoomStatus.transferring);
      final restored = Room.fromJson(room.toJson());

      expect(restored, room);
      expect(restored.members.map((m) => m.deviceId), ['a', 'b']);
    });

    test('reports open/closed state', () {
      final room = _room();
      expect(room.isOpen, isTrue);
      expect(room.isClosed, isFalse);
      expect(room.copyWith(status: RoomStatus.closed).isOpen, isFalse);
    });
  });

  group('RoomMember', () {
    test('round-trips through JSON', () {
      final member = _member('a');
      expect(RoomMember.fromJson(member.toJson()), member);
      expect(member.toDevice().ipAddress, member.ipAddress);
    });
  });
}
