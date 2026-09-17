import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import '../domain/device.dart';

abstract class MdnsDiscoveryService {
  Stream<Device> get onDeviceDiscovered;
  Stream<String> get onDeviceLost;
  bool get isBroadcasting;
  bool get isScanning;

  Future<void> startBroadcast({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int port,
  });

  Future<void> stopBroadcast();

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<void> dispose();
}

class BonsoirMdnsDiscoveryService implements MdnsDiscoveryService {
  static const String serviceType = '_nearshare._tcp';

  final StreamController<Device> _deviceDiscoveredController =
      StreamController<Device>.broadcast();
  final StreamController<String> _deviceLostController =
      StreamController<String>.broadcast();

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;

  bool _isBroadcasting = false;
  bool _isScanning = false;
  String? _currentLocalDeviceId;

  @override
  Stream<Device> get onDeviceDiscovered => _deviceDiscoveredController.stream;

  @override
  Stream<String> get onDeviceLost => _deviceLostController.stream;

  @override
  bool get isBroadcasting => _isBroadcasting;

  @override
  bool get isScanning => _isScanning;

  @override
  Future<void> startBroadcast({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int port,
  }) async {
    if (kIsWeb) {
      debugPrint('[BonsoirMdns] mDNS broadcast skipped on Web platform');
      _isBroadcasting = true;
      return;
    }

    await stopBroadcast();
    _currentLocalDeviceId = deviceId;

    try {
      final service = BonsoirService(
        name: deviceName,
        type: serviceType,
        port: port,
        attributes: {
          'id': deviceId,
          'name': deviceName,
          'platform': platform,
        },
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.start();
      _isBroadcasting = true;
      debugPrint('[BonsoirMdns] Broadcast started for $deviceName (ID: $deviceId) on port $port');
    } catch (e, stack) {
      debugPrint('[BonsoirMdns] Error starting broadcast: $e\n$stack');
      _isBroadcasting = false;
      rethrow;
    }
  }

  @override
  Future<void> stopBroadcast() async {
    if (_broadcast != null) {
      try {
        await _broadcast!.stop();
      } catch (e) {
        debugPrint('[BonsoirMdns] Error stopping broadcast: $e');
      }
      _broadcast = null;
    }
    _isBroadcasting = false;
  }

  @override
  Future<void> startDiscovery() async {
    if (kIsWeb) {
      debugPrint('[BonsoirMdns] mDNS discovery skipped on Web platform');
      _isScanning = true;
      return;
    }

    await stopDiscovery();

    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      _discoverySubscription = _discovery!.eventStream?.listen(
        _handleDiscoveryEvent,
        onError: (err) {
          debugPrint('[BonsoirMdns] Discovery stream error: $err');
        },
      );

      await _discovery!.start();
      _isScanning = true;
      debugPrint('[BonsoirMdns] Discovery scanning started for $serviceType');
    } catch (e, stack) {
      debugPrint('[BonsoirMdns] Error starting discovery: $e\n$stack');
      _isScanning = false;
      rethrow;
    }
  }

  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      debugPrint('[BonsoirMdns] Service found: ${event.service.name}, resolving...');
      if (_discovery != null) {
        event.service.resolve(_discovery!.serviceResolver);
      }
    } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
      final service = event.service;
      final attributes = service.attributes;
      final peerId = attributes['id'] ?? service.name;
      final peerName = attributes['name'] ?? service.name;
      final peerPlatform = attributes['platform'] ?? 'unknown';
      final peerIp = service.host ?? '';
      final peerPort = service.port;

      // Ignore own broadcast
      if (_currentLocalDeviceId != null && peerId == _currentLocalDeviceId) {
        debugPrint('[BonsoirMdns] Ignoring own device resolution: $peerId');
        return;
      }

      final device = Device(
        id: peerId,
        name: peerName,
        platform: peerPlatform,
        ipAddress: peerIp,
        port: peerPort,
        discoveredAt: DateTime.now(),
      );

      debugPrint('[BonsoirMdns] Discovered device: ${device.name} ($peerIp:$peerPort)');
      _deviceDiscoveredController.add(device);
    } else if (event is BonsoirDiscoveryServiceLostEvent) {
      final service = event.service;
      final lostIdentifier = service.attributes['id'] ?? service.name;
      debugPrint('[BonsoirMdns] Service lost: $lostIdentifier (${service.name})');
      if (lostIdentifier.isNotEmpty) {
        _deviceLostController.add(lostIdentifier);
      }
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;

    if (_discovery != null) {
      try {
        await _discovery!.stop();
      } catch (e) {
        debugPrint('[BonsoirMdns] Error stopping discovery: $e');
      }
      _discovery = null;
    }
    _isScanning = false;
  }

  @override
  Future<void> dispose() async {
    await stopBroadcast();
    await stopDiscovery();
    await _deviceDiscoveredController.close();
    await _deviceLostController.close();
  }
}
