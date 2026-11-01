import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

/// A room advertised on the local network.
class RoomAnnouncement {
  final String roomId;
  final String roomCode;
  final String hostName;
  final String hostIp;
  final int port;
  final int memberCount;

  const RoomAnnouncement({
    required this.roomId,
    required this.roomCode,
    required this.hostName,
    required this.hostIp,
    required this.port,
    this.memberCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'hostName': hostName,
      'hostIp': hostIp,
      'port': port,
      'memberCount': memberCount,
    };
  }

  factory RoomAnnouncement.fromJson(Map<String, dynamic> json) {
    return RoomAnnouncement(
      roomId: json['roomId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      hostName: json['hostName'] as String? ?? 'Unknown Host',
      hostIp: json['hostIp'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'RoomAnnouncement($roomCode by $hostName at $hostIp:$port)';
}

abstract class RoomDiscoveryService {
  Stream<RoomAnnouncement> get onRoomDiscovered;

  Future<void> startBroadcast({
    required String roomId,
    required String roomCode,
    required String hostName,
    required String hostIp,
    required int port,
    int memberCount = 0,
  });

  Future<void> stopBroadcast();

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> dispose();
}

/// mDNS implementation using the `_nearshare-room._tcp` service type.
class BonsoirRoomDiscoveryService implements RoomDiscoveryService {
  static const String serviceType = '_nearshare-room._tcp';

  final StreamController<RoomAnnouncement> _discoveredController =
      StreamController<RoomAnnouncement>.broadcast();

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  String? _currentRoomId;

  @override
  Stream<RoomAnnouncement> get onRoomDiscovered =>
      _discoveredController.stream;

  @override
  Future<void> startBroadcast({
    required String roomId,
    required String roomCode,
    required String hostName,
    required String hostIp,
    required int port,
    int memberCount = 0,
  }) async {
    if (kIsWeb) {
      debugPrint('[RoomDiscovery] Broadcast skipped on Web');
      return;
    }

    await stopBroadcast();
    _currentRoomId = roomId;

    try {
      final service = BonsoirService(
        name: '$hostName-$roomCode',
        type: serviceType,
        port: port,
        attributes: {
          'roomId': roomId,
          'roomCode': roomCode,
          'hostName': hostName,
          'hostIp': hostIp,
          'memberCount': '$memberCount',
        },
      );
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.start();
      debugPrint('[RoomDiscovery] Broadcasting room $roomCode on port $port');
    } catch (e, stack) {
      debugPrint('[RoomDiscovery] Broadcast error: $e\n$stack');
      _broadcast = null;
      rethrow;
    }
  }

  @override
  Future<void> stopBroadcast() async {
    if (_broadcast != null) {
      try {
        await _broadcast!.stop();
      } catch (e) {
        debugPrint('[RoomDiscovery] Error stopping broadcast: $e');
      }
      _broadcast = null;
    }
    _currentRoomId = null;
  }

  @override
  Future<void> startDiscovery() async {
    if (kIsWeb) {
      debugPrint('[RoomDiscovery] Discovery skipped on Web');
      return;
    }

    await stopDiscovery();
    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      _subscription = _discovery!.eventStream?.listen(
        _handleEvent,
        onError: (Object error) {
          debugPrint('[RoomDiscovery] Discovery error: $error');
        },
      );
      await _discovery!.start();
      debugPrint('[RoomDiscovery] Scanning for $serviceType');
    } catch (e, stack) {
      debugPrint('[RoomDiscovery] Discovery start error: $e\n$stack');
      _discovery = null;
      rethrow;
    }
  }

  void _handleEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      event.service.resolve(_discovery!.serviceResolver);
    } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
      final service = event.service;
      final attributes = service.attributes;
      final roomId = attributes['roomId'] ?? '';
      if (roomId.isEmpty) return;
      if (_currentRoomId != null && roomId == _currentRoomId) return;

      final code = attributes['roomCode'] ?? '';
      if (code.isEmpty) return;

      final announcement = RoomAnnouncement(
        roomId: roomId,
        roomCode: code,
        hostName: attributes['hostName'] ?? service.name,
        hostIp: service.host ?? (attributes['hostIp'] ?? ''),
        port: service.port,
        memberCount: int.tryParse(attributes['memberCount'] ?? '') ?? 0,
      );
      if (!_discoveredController.isClosed) {
        _discoveredController.add(announcement);
      }
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_discovery != null) {
      try {
        await _discovery!.stop();
      } catch (e) {
        debugPrint('[RoomDiscovery] Error stopping discovery: $e');
      }
      _discovery = null;
    }
  }

  @override
  Future<void> dispose() async {
    await stopBroadcast();
    await stopDiscovery();
    await _discoveredController.close();
  }
}
