/// Real-time room events exchanged with joined members.
enum RoomEventType {
  memberJoined,
  memberLeft,
  memberDisconnected,
  transferStarted,
  transferProgress,
  transferCompleted,
  roomClosed,
}

/// Immutable event payload broadcast over SSE or the in-process event bus.
class RoomEvent {
  final RoomEventType type;
  final String roomId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  RoomEvent({
    required this.type,
    required this.roomId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'roomId': roomId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    return RoomEvent(
      type: RoomEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => RoomEventType.memberJoined,
      ),
      roomId: json['roomId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          roomId == other.roomId &&
          timestamp.isAtSameMomentAs(other.timestamp) &&
          _mapEquals(data, other.data);

  @override
  int get hashCode =>
      type.hashCode ^ roomId.hashCode ^ timestamp.hashCode ^ data.length;

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() => 'RoomEvent(${type.name}, room: $roomId)';
}
