import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/room.dart';
import '../domain/room_event.dart';
import '../domain/room_member.dart';
import 'room_code_generator.dart';
import 'room_event_service.dart';

/// Why a join request was turned away.
enum JoinRejectionReason {
  noActiveRoom,
  invalidCode,
  roomClosed,
  roomFull,
  invalidMember;

  String get message {
    switch (this) {
      case JoinRejectionReason.noActiveRoom:
        return 'Room not found';
      case JoinRejectionReason.invalidCode:
        return 'Wrong room code';
      case JoinRejectionReason.roomClosed:
        return 'Room is closed';
      case JoinRejectionReason.roomFull:
        return 'Room is full';
      case JoinRejectionReason.invalidMember:
        return 'Invalid device information';
    }
  }
}

/// Result of a member asking to join the room.
class RoomJoinResult {
  final bool accepted;
  final JoinRejectionReason? reason;
  final Room? room;

  const RoomJoinResult.accepted(Room this.room)
      : accepted = true,
        reason = null;

  const RoomJoinResult.rejected(JoinRejectionReason this.reason)
      : accepted = false,
        room = null;

  String get message => accepted ? 'Joined' : reason!.message;

  @override
  String toString() =>
      'RoomJoinResult(accepted: $accepted, reason: ${reason?.name})';
}

/// Owns the room lifecycle on the host device.
///
/// Network concerns live in [RoomServer] and [RoomDiscoveryService]; this class
/// is deliberately transport-agnostic so the lifecycle rules (capacity, code
/// validation, teardown notifications) can be unit tested without sockets.
class RoomManager {
  final RoomCodeGenerator _codeGenerator;
  final RoomEventService _eventService;
  final Uuid _uuid;

  final StreamController<Room> _roomUpdates =
      StreamController<Room>.broadcast();

  Room? _room;

  RoomManager({
    RoomCodeGenerator? codeGenerator,
    RoomEventService? eventService,
    Uuid? uuid,
  })  : _codeGenerator = codeGenerator ?? RoomCodeGenerator(),
        _eventService = eventService ?? RoomEventService(),
        _uuid = uuid ?? const Uuid();

  Room? get currentRoom => _room;

  bool get hasActiveRoom => _room != null && !_room!.isClosed;

  Stream<Room> get onRoomUpdated => _roomUpdates.stream;

  Stream<RoomEvent> get events => _eventService.events;

  RoomEventService get eventService => _eventService;

  /// Creates a fresh room owned by the local device.
  ///
  /// The generated code is guaranteed to be 6 numeric digits. Call [closeRoom]
  /// on the previous room before creating another.
  Room createRoom({
    required String hostDeviceId,
    required String hostDeviceName,
    required String hostIpAddress,
    required int hostPort,
    String? roomCode,
  }) {
    if (hasActiveRoom) {
      throw StateError('A room is already active');
    }
    if (roomCode != null && !RoomCodeGenerator.isValid(roomCode)) {
      throw ArgumentError.value(roomCode, 'roomCode', 'Must be 6 digits');
    }

    final room = Room(
      roomId: _uuid.v4(),
      roomCode: roomCode ?? _codeGenerator.generate(),
      hostDeviceId: hostDeviceId,
      hostDeviceName: hostDeviceName,
      hostIpAddress: hostIpAddress,
      hostPort: hostPort,
      members: const [],
      status: RoomStatus.waiting,
      createdAt: DateTime.now(),
    );

    _room = room;
    _publish(room);
    return room;
  }

  /// Validates a join request and, when accepted, updates the room.
  RoomJoinResult handleJoinRequest({
    required String roomCode,
    required RoomMember member,
  }) {
    final room = _room;
    if (room == null) {
      return const RoomJoinResult.rejected(JoinRejectionReason.noActiveRoom);
    }
    if (room.isClosed) {
      return const RoomJoinResult.rejected(JoinRejectionReason.roomClosed);
    }
    if (roomCode != room.roomCode) {
      return const RoomJoinResult.rejected(JoinRejectionReason.invalidCode);
    }
    if (member.deviceId.trim().isEmpty) {
      return const RoomJoinResult.rejected(JoinRejectionReason.invalidMember);
    }
    if (room.isFull && room.memberById(member.deviceId) == null) {
      return const RoomJoinResult.rejected(JoinRejectionReason.roomFull);
    }

    final updated = room.addMember(member);
    _room = updated;
    _publish(updated);
    _eventService.emit(
      RoomEvent(
        type: RoomEventType.memberJoined,
        roomId: updated.roomId,
        data: {
          'member': member.toJson(),
          'memberCount': updated.memberCount,
        },
      ),
    );

    return RoomJoinResult.accepted(updated);
  }

  /// Removes a member and notifies everyone still in the room.
  bool leaveRoom(String deviceId) {
    final room = _room;
    if (room == null || room.isClosed) return false;
    final member = room.memberById(deviceId);
    if (member == null) return false;

    final updated = room.removeMember(deviceId);
    _room = updated;
    _publish(updated);
    _eventService.emit(
      RoomEvent(
        type: RoomEventType.memberLeft,
        roomId: updated.roomId,
        data: {
          'deviceId': deviceId,
          'deviceName': member.deviceName,
          'memberCount': updated.memberCount,
        },
      ),
    );
    return true;
  }

  /// Marks a member as unreachable without removing them from the roster.
  bool markMemberDisconnected(String deviceId) {
    final room = _room;
    if (room == null || room.isClosed) return false;
    final member = room.memberById(deviceId);
    if (member == null) return false;

    final updatedMember = member.copyWith(status: RoomMemberStatus.disconnected);
    final updated = room.updateMember(updatedMember);
    _room = updated;
    _publish(updated);
    _eventService.emit(
      RoomEvent(
        type: RoomEventType.memberDisconnected,
        roomId: updated.roomId,
        data: {
          'deviceId': deviceId,
          'deviceName': member.deviceName,
        },
      ),
    );
    return true;
  }

  /// Updates the room's lifecycle status (`transferring`, `completed`, ...).
  void updateStatus(RoomStatus status) {
    final room = _room;
    if (room == null || room.isClosed) return;
    _room = room.copyWith(status: status);
    _publish(_room!);
  }

  /// Emits an arbitrary room event, used by the transfer service.
  void emitEvent(RoomEvent event) => _eventService.emit(event);

  /// Closes the room and notifies every connected member.
  ///
  /// The closed room is kept locally so the UI can render a final state; it
  /// stops accepting joins immediately.
  Future<void> closeRoom() async {
    final room = _room;
    if (room == null) return;
    if (room.isClosed) return;

    final closed = room.copyWith(status: RoomStatus.closed);
    _room = closed;
    _eventService.emit(
      RoomEvent(
        type: RoomEventType.roomClosed,
        roomId: closed.roomId,
        data: {
          'hostDeviceId': closed.hostDeviceId,
          'memberIds': closed.members.map((m) => m.deviceId).toList(),
        },
      ),
    );
    _publish(closed);
  }

  void _publish(Room room) {
    if (!_roomUpdates.isClosed) _roomUpdates.add(room);
  }

  Future<void> dispose() async {
    await _roomUpdates.close();
    await _eventService.close();
  }
}
