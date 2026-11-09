import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

/// A Merge Space peer advertised on the local network.
class MergePeerAnnouncement {
  final String groupId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String hostIp;
  final int port;

  const MergePeerAnnouncement({
    required this.groupId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.hostIp,
    required this.port,
  });

  @override
  String toString() =>
      'MergePeerAnnouncement($deviceName at $hostIp:$port for $groupId)';
}

abstract class MergeDiscoveryService {
  Stream<MergePeerAnnouncement> get onPeerDiscovered;

  Stream<String> get onPeerLost;

  Future<void> startBroadcast({
    required String groupId,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String hostIp,
    required int port,
  });

  Future<void> stopBroadcast();

  Future<void> startDiscovery({required String groupId});

  Future<void> stopDiscovery();

  Future<void> dispose();
}

/// mDNS implementation using the `_nearshare-merge._tcp` service type.
class BonsoirMergeDiscoveryService implements MergeDiscoveryService {
  static const String serviceType = '_nearshare-merge._tcp';

  final StreamController<MergePeerAnnouncement> _controller =
      StreamController<MergePeerAnnouncement>.broadcast();
  final StreamController<String> _lostController =
      StreamController<String>.broadcast();

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  String? _ownDeviceId;
  String? _groupFilter;

  @override
  Stream<MergePeerAnnouncement> get onPeerDiscovered => _controller.stream;

  @override
  Stream<String> get onPeerLost => _lostController.stream;

  @override
  Future<void> startBroadcast({
    required String groupId,
    required String deviceId,
    required String deviceName,
    required String platform,
    required String hostIp,
    required int port,
  }) async {
    if (kIsWeb) {
      debugPrint('[MergeDiscovery] Broadcast skipped on Web');
      return;
    }

    await stopBroadcast();
    _ownDeviceId = deviceId;

    try {
      final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;
      final service = BonsoirService(
        name: '${_sanitize(deviceName)}-$shortId',
        type: serviceType,
        port: port,
        attributes: {
          'groupId': groupId,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'platform': platform,
          'hostIp': hostIp,
        },
      );
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();
      await _broadcast!.start();
      debugPrint('[MergeDiscovery] Broadcasting Merge Space on port $port');
    } catch (error, stack) {
      debugPrint('[MergeDiscovery] Broadcast error: $error\n$stack');
      _broadcast = null;
      rethrow;
    }
  }

  @override
  Future<void> stopBroadcast() async {
    if (_broadcast != null) {
      try {
        await _broadcast!.stop();
      } catch (error) {
        debugPrint('[MergeDiscovery] Error stopping broadcast: $error');
      }
      _broadcast = null;
    }
  }

  @override
  Future<void> startDiscovery({required String groupId}) async {
    if (kIsWeb) {
      debugPrint('[MergeDiscovery] Discovery skipped on Web');
      return;
    }

    await stopDiscovery();
    _groupFilter = groupId;

    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.initialize();
      _subscription = _discovery!.eventStream?.listen(
        _handleEvent,
        onError: (Object error) {
          debugPrint('[MergeDiscovery] Discovery error: $error');
        },
      );
      await _discovery!.start();
      debugPrint('[MergeDiscovery] Scanning for $serviceType');
    } catch (error, stack) {
      debugPrint('[MergeDiscovery] Discovery start error: $error\n$stack');
      _discovery = null;
      rethrow;
    }
  }

  void _handleEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      event.service.resolve(_discovery!.serviceResolver);
      return;
    }
    if (event is BonsoirDiscoveryServiceLostEvent) {
      final deviceId = event.service.attributes['deviceId'] ?? '';
      if (deviceId.isNotEmpty && !_lostController.isClosed) {
        _lostController.add(deviceId);
      }
      return;
    }
    if (event is! BonsoirDiscoveryServiceResolvedEvent) return;

    final service = event.service;
    final attributes = service.attributes;
    final groupId = attributes['groupId'] ?? '';
    final deviceId = attributes['deviceId'] ?? '';
    if (groupId.isEmpty || deviceId.isEmpty) return;
    if (_groupFilter != null && groupId != _groupFilter) return;
    if (_ownDeviceId != null && deviceId == _ownDeviceId) return;

    final announcement = MergePeerAnnouncement(
      groupId: groupId,
      deviceId: deviceId,
      deviceName: attributes['deviceName'] ?? service.name,
      platform: attributes['platform'] ?? 'unknown',
      hostIp: service.host ?? (attributes['hostIp'] ?? ''),
      port: service.port,
    );
    if (announcement.hostIp.isEmpty) {
      debugPrint('[MergeDiscovery] Ignoring peer without host address');
      return;
    }
    if (!_controller.isClosed) {
      _controller.add(announcement);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_discovery != null) {
      try {
        await _discovery!.stop();
      } catch (error) {
        debugPrint('[MergeDiscovery] Error stopping discovery: $error');
      }
      _discovery = null;
    }
    _groupFilter = null;
  }

  @override
  Future<void> dispose() async {
    await stopBroadcast();
    await stopDiscovery();
    await _controller.close();
    await _lostController.close();
  }

  static String _sanitize(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    return cleaned.isEmpty ? 'NearShare' : cleaned;
  }
}
