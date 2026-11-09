import '../../discovery/domain/device.dart';

/// Connection / transfer state of a single room participant.
enum RoomMemberStatus {
  connected,
  disconnected,
  sending,
  completed,
  failed;

  bool get isActive => this == sending;

  bool get isFinished =>
      this == completed || this == failed || this == disconnected;
}

/// A device that has joined a room.
class RoomMember {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final int port;
  final DateTime joinedAt;
  final RoomMemberStatus status;

  const RoomMember({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.port,
    required this.joinedAt,
    this.status = RoomMemberStatus.connected,
  });

  RoomMember copyWith({
    String? deviceId,
    String? deviceName,
    String? platform,
    String? ipAddress,
    int? port,
    DateTime? joinedAt,
    RoomMemberStatus? status,
  }) {
    return RoomMember(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
    );
  }

  /// Peer representation used by the existing transfer stack.
  Device toDevice() {
    return Device(
      id: deviceId,
      name: deviceName,
      platform: platform,
      ipAddress: ipAddress,
      port: port,
      discoveredAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'ipAddress': ipAddress,
      'port': port,
      'joinedAt': joinedAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'unknown',
      ipAddress: json['ipAddress'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: RoomMemberStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => RoomMemberStatus.connected,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMember &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          deviceName == other.deviceName &&
          platform == other.platform &&
          ipAddress == other.ipAddress &&
          port == other.port &&
          joinedAt.isAtSameMomentAs(other.joinedAt) &&
          status == other.status;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      deviceName.hashCode ^
      platform.hashCode ^
      ipAddress.hashCode ^
      port.hashCode ^
      joinedAt.hashCode ^
      status.hashCode;

  @override
  String toString() =>
      'RoomMember(id: $deviceId, name: $deviceName, $ipAddress:$port, '
      'status: ${status.name})';
}
