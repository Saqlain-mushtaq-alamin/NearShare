import 'room_member.dart';

/// Lifecycle of a temporary group-sharing session.
enum RoomStatus {
  waiting,
  transferring,
  completed,
  closed;

  bool get isOpen => this != closed;
}

/// A temporary group file-sharing session hosted by one device.
class Room {
  /// Suggested maximum number of joined devices (the host is not counted).
  static const int maxMembers = 10;

  final String roomId;
  final String roomCode;
  final String hostDeviceId;
  final String hostDeviceName;
  final String hostIpAddress;
  final int hostPort;
  final List<RoomMember> members;
  final RoomStatus status;
  final DateTime createdAt;

  const Room({
    required this.roomId,
    required this.roomCode,
    required this.hostDeviceId,
    required this.hostDeviceName,
    required this.members,
    required this.status,
    required this.createdAt,
    this.hostIpAddress = '',
    this.hostPort = 0,
  });

  int get memberCount => members.length;

  bool get isFull => members.length >= maxMembers;

  bool get isEmpty => members.isEmpty;

  bool get isClosed => status == RoomStatus.closed;

  bool get isOpen => !isClosed;

  Room copyWith({
    String? roomId,
    String? roomCode,
    String? hostDeviceId,
    String? hostDeviceName,
    String? hostIpAddress,
    int? hostPort,
    List<RoomMember>? members,
    RoomStatus? status,
    DateTime? createdAt,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      hostDeviceId: hostDeviceId ?? this.hostDeviceId,
      hostDeviceName: hostDeviceName ?? this.hostDeviceName,
      hostIpAddress: hostIpAddress ?? this.hostIpAddress,
      hostPort: hostPort ?? this.hostPort,
      members: members ?? this.members,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Adds [member], replacing an existing entry with the same device id.
  ///
  /// Throws a [StateError] when the room is already full.
  Room addMember(RoomMember member) {
    final index = members.indexWhere((m) => m.deviceId == member.deviceId);
    if (index >= 0) {
      final updated = List<RoomMember>.from(members)..[index] = member;
      return copyWith(members: updated);
    }
    if (isFull) {
      throw StateError('Room $roomId is full');
    }
    return copyWith(members: [...members, member]);
  }

  /// Removes the member with [deviceId]. Returns the same room when absent.
  Room removeMember(String deviceId) {
    final updated =
        members.where((member) => member.deviceId != deviceId).toList();
    if (updated.length == members.length) return this;
    return copyWith(members: updated);
  }

  Room updateMember(RoomMember member) {
    final index = members.indexWhere((m) => m.deviceId == member.deviceId);
    if (index < 0) return this;
    final updated = List<RoomMember>.from(members)..[index] = member;
    return copyWith(members: updated);
  }

  RoomMember? memberById(String deviceId) {
    for (final member in members) {
      if (member.deviceId == deviceId) return member;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'hostDeviceId': hostDeviceId,
      'hostDeviceName': hostDeviceName,
      'hostIpAddress': hostIpAddress,
      'hostPort': hostPort,
      'members': members.map((member) => member.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return Room(
      roomId: json['roomId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      hostDeviceId: json['hostDeviceId'] as String? ?? '',
      hostDeviceName: json['hostDeviceName'] as String? ?? 'Unknown Host',
      hostIpAddress: json['hostIpAddress'] as String? ?? '',
      hostPort: json['hostPort'] as int? ?? 0,
      members: rawMembers
          .map((item) => RoomMember.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: RoomStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RoomStatus.waiting,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          runtimeType == other.runtimeType &&
          roomId == other.roomId &&
          roomCode == other.roomCode &&
          hostDeviceId == other.hostDeviceId &&
          hostDeviceName == other.hostDeviceName &&
          hostIpAddress == other.hostIpAddress &&
          hostPort == other.hostPort &&
          status == other.status &&
          createdAt.isAtSameMomentAs(other.createdAt) &&
          _listEquals(members, other.members);

  @override
  int get hashCode => Object.hash(
        roomId,
        roomCode,
        hostDeviceId,
        hostDeviceName,
        hostIpAddress,
        hostPort,
        status,
        createdAt,
        Object.hashAll(members),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Room(id: $roomId, code: $roomCode, host: $hostDeviceName, '
      'members: ${members.length}, status: ${status.name})';
}
