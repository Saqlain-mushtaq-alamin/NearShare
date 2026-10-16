import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/device_identity_service.dart';
import '../data/mdns_discovery_service.dart';
import '../domain/device.dart';
import '../domain/discovery_state.dart';

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

final mdnsDiscoveryServiceProvider = Provider<MdnsDiscoveryService>((ref) {
  final service = BonsoirMdnsDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

final discoveryStateProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final identityService = ref.watch(deviceIdentityServiceProvider);
  final discoveryService = ref.watch(mdnsDiscoveryServiceProvider);
  return DiscoveryNotifier(identityService, discoveryService);
});

class DiscoveryNotifier extends StateNotifier<DiscoveryState>
    with WidgetsBindingObserver {
  final DeviceIdentityService _identityService;
  final MdnsDiscoveryService _discoveryService;

  StreamSubscription<Device>? _discoveredSub;
  StreamSubscription<String>? _lostSub;
  bool _initialized = false;

  DiscoveryNotifier(this._identityService, this._discoveryService)
      : super(const DiscoveryState()) {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  /// Tests subclass [DiscoveryNotifier] with in-memory collaborators and seed
  /// their own state; they override this to skip the auto-start side effects.
  @protected
  bool get autoInitialize => true;

  Future<void> _initialize() async {
    if (_initialized || !autoInitialize) return;
    _initialized = true;

    try {
      final local = await _identityService.getLocalDevice();
      state = state.copyWith(localDevice: local);

      // Listen to discovery streams
      _discoveredSub = _discoveryService.onDeviceDiscovered.listen(_onDeviceDiscovered);
      _lostSub = _discoveryService.onDeviceLost.listen(_onDeviceLost);

      // Automatically begin broadcast and discovery
      await startBroadcast();
      await startScanning();
    } catch (e) {
      state = state.copyWith(
        status: DiscoveryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _onDeviceDiscovered(Device device) {
    // Avoid listing self
    if (state.localDevice != null && device.id == state.localDevice!.id) {
      return;
    }

    final updated = List<Device>.from(state.devices);
    final existingIndex = updated.indexWhere(
      (d) => d.id == device.id || (d.ipAddress == device.ipAddress && d.port == device.port),
    );

    if (existingIndex >= 0) {
      updated[existingIndex] = device;
    } else {
      updated.add(device);
    }

    state = state.copyWith(
      devices: updated,
      clearErrorMessage: true,
    );
  }

  void _onDeviceLost(String deviceIdentifier) {
    final updated = state.devices.where((d) {
      return d.id != deviceIdentifier && d.name != deviceIdentifier;
    }).toList();

    state = state.copyWith(devices: updated);
  }

  Future<void> startBroadcast() async {
    try {
      var local = state.localDevice;
      local ??= await _identityService.getLocalDevice();

      await _discoveryService.startBroadcast(
        deviceId: local.id,
        deviceName: local.name,
        platform: local.platform,
        port: local.port,
      );

      state = state.copyWith(
        isBroadcasting: true,
        localDevice: local,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isBroadcasting: false,
        errorMessage: 'Failed to broadcast device: $e',
      );
    }
  }

  Future<void> stopBroadcast() async {
    try {
      await _discoveryService.stopBroadcast();
      state = state.copyWith(isBroadcasting: false);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to stop broadcast: $e');
    }
  }

  Future<void> startScanning() async {
    try {
      state = state.copyWith(
        status: DiscoveryStatus.scanning,
        clearErrorMessage: true,
      );
      await _discoveryService.startDiscovery();
    } catch (e) {
      state = state.copyWith(
        status: DiscoveryStatus.error,
        errorMessage: 'Failed to start scanning: $e',
      );
    }
  }

  Future<void> stopScanning() async {
    try {
      await _discoveryService.stopDiscovery();
      state = state.copyWith(status: DiscoveryStatus.idle);
    } catch (e) {
      state = state.copyWith(
        status: DiscoveryStatus.error,
        errorMessage: 'Failed to stop scanning: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(devices: const []);
    await stopScanning();
    await startScanning();
  }

  Future<void> updateLocalDeviceName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    await _identityService.setDeviceName(trimmed);
    final updatedLocal = await _identityService.getLocalDevice();
    state = state.copyWith(localDevice: updatedLocal);

    if (state.isBroadcasting) {
      await stopBroadcast();
      await startBroadcast();
    }
  }

  void addSimulatedDevice(Device device) {
    _onDeviceDiscovered(device);
  }

  void removeSimulatedDevice(String deviceId) {
    _onDeviceLost(deviceId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (this.state.isBroadcasting) {
        startBroadcast();
      }
      if (this.state.status == DiscoveryStatus.scanning) {
        startScanning();
      }
    } else if (state == AppLifecycleState.paused) {
      _discoveryService.stopBroadcast();
      _discoveryService.stopDiscovery();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discoveredSub?.cancel();
    _lostSub?.cancel();
    super.dispose();
  }
}
