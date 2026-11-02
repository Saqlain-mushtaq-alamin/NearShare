import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/data/device_identity_service.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../data/group_credential_store.dart';
import '../data/local_database.dart' show openDefaultMergeSpaceDatabase;
import '../data/merge_discovery_service.dart';
import '../data/merge_protocol.dart';
import '../data/merge_folder_watcher.dart';
import '../data/merge_space_client.dart';
import '../data/merge_space_repository.dart';
import '../data/merge_space_server.dart';
import '../data/merge_space_storage.dart';
import '../data/merge_sync_scheduler.dart';
import '../data/merge_sync_service.dart';
import '../data/pairing_service.dart';
import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import '../domain/sync_conflict.dart';
import 'merge_space_state.dart';

final mergeSpaceRepositoryProvider = Provider<MergeSpaceRepository>((ref) {
  final repository = DriftMergeSpaceRepository(openDefaultMergeSpaceDatabase());
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final mergeSpaceStorageProvider = Provider<MergeSpaceStorage>((ref) {
  return MergeSpaceStorage();
});

final mergeCredentialStoreProvider = Provider<GroupCredentialStore>((ref) {
  return SecureGroupCredentialStore();
});

final mergeDiscoveryProvider = Provider<MergeDiscoveryService>((ref) {
  return BonsoirMergeDiscoveryService();
});

final mergeSpaceProvider =
    StateNotifierProvider<MergeSpaceNotifier, MergeSpaceState>((ref) {
  return MergeSpaceNotifier(
    repository: ref.watch(mergeSpaceRepositoryProvider),
    storage: ref.watch(mergeSpaceStorageProvider),
    credentialStore: ref.watch(mergeCredentialStoreProvider),
    discovery: ref.watch(mergeDiscoveryProvider),
    identityService: ref.watch(deviceIdentityServiceProvider),
  );
});

/// Owns the Merge Space lifecycle: pairing, LAN server, discovery, watcher and
/// periodic delta sync.
class MergeSpaceNotifier extends StateNotifier<MergeSpaceState> {
  final MergeSpaceRepository _repository;
  final MergeSpaceStorage _storage;
  final GroupCredentialStore _credentialStore;
  final MergeDiscoveryService _discovery;
  final DeviceIdentityService _identityService;
  final MergeSpaceClient _client;
  final PairingService _pairingService;
  final MergeSyncService _syncService;
  final bool _autoStartRuntime;

  MergeSpaceServer? _server;
  MergeSyncScheduler? _scheduler;
  MergeFolderWatcher? _watcher;
  StreamSubscription<MergePeerAnnouncement>? _peerSubscription;
  StreamSubscription<String>? _peerLostSubscription;
  final Map<String, MergePeerAnnouncement> _peers = {};
  String? _localIp;
  int? _port;
  bool _disposed = false;

  MergeSpaceNotifier({
    required MergeSpaceRepository repository,
    required MergeSpaceStorage storage,
    required GroupCredentialStore credentialStore,
    required MergeDiscoveryService discovery,
    required DeviceIdentityService identityService,
    MergeSpaceClient? client,
    PairingService? pairingService,
    MergeSyncService? syncService,
    bool autoStartRuntime = true,
  })  : _repository = repository,
        _storage = storage,
        _credentialStore = credentialStore,
        _discovery = discovery,
        _identityService = identityService,
        _client = client ?? MergeSpaceClient(),
        _pairingService = pairingService ?? PairingService(),
        _syncService = syncService ??
            MergeSyncService(repository: repository, storage: storage),
        _autoStartRuntime = autoStartRuntime,
        super(const MergeSpaceState()) {
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final credentials = await _credentialStore.load();
      final files = await _repository.getAllFiles();
      final conflicts = await _repository.getConflicts();

      if (credentials == null) {
        _setState(
          state.copyWith(
            isInitialized: true,
            files: files,
            conflicts: conflicts,
          ),
        );
        return;
      }

      final device = await _identityService.getLocalDevice();
      final local = _toPairedDevice(device, credentials.groupId);
      var devices = await _repository.getDevices();
      if (!devices.any((item) => item.deviceId == local.deviceId)) {
        devices = [...devices, local];
        await _repository.saveDevice(local);
      }

      final group = DeviceGroup(
        groupId: credentials.groupId,
        groupKey: credentials.groupKey,
        devices: devices,
        createdAt: credentials.createdAt,
      );

      _setState(
        state.copyWith(
          isInitialized: true,
          isActive: true,
          group: group,
          localDevice: local,
          devices: _peersOnly(group, local.deviceId),
          files: files,
          conflicts: conflicts,
        ),
      );

      if (_autoStartRuntime) await _startRuntime();
    } catch (error, stack) {
      debugPrint('[MergeSpaceNotifier] Init failed: $error\n$stack');
      _setState(
        state.copyWith(
          isInitialized: true,
          errorMessage: 'Could not load Merge Space: $error',
        ),
      );
    }
  }

  bool get isActive => state.hasGroup;

  Future<void> createGroup() async {
    if (state.isBusy) return;
    if (state.hasGroup) {
      _setState(
        state.copyWith(errorMessage: 'A Merge Space already exists here.'),
      );
      return;
    }

    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      final device = await _identityService.getLocalDevice();
      final group = _pairingService.createGroup();
      final local = _toPairedDevice(device, group.groupId);
      final withSelf = group.addOrUpdateDevice(local);

      await _credentialStore.save(
        MergedGroupCredentials(
          groupId: withSelf.groupId,
          groupKey: withSelf.groupKey,
          createdAt: withSelf.createdAt,
        ),
      );
      await _repository.saveDevice(local);

      _setState(
        state.copyWith(
          isBusy: false,
          isActive: true,
          group: withSelf,
          localDevice: local,
          devices: const [],
          clearError: true,
        ),
      );
      if (_autoStartRuntime) await _startRuntime();
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] createGroup failed: $error');
      _setState(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Could not create Merge Space: $error',
        ),
      );
    }
  }

  Future<bool> joinWithLink(String rawLink) async {
    if (state.isBusy) return false;
    if (state.hasGroup) {
      _setState(
        state.copyWith(errorMessage: 'Leave the current Merge Space first.'),
      );
      return false;
    }

    final link = _pairingService.parse(rawLink);
    if (link == null) {
      _setState(
        state.copyWith(errorMessage: 'That pairing code is not valid.'),
      );
      return false;
    }

    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      final device = await _identityService.getLocalDevice();
      final local = _toPairedDevice(device, link.groupId);

      final remoteGroup = await _client.pair(
        host: link.host,
        port: link.port,
        groupId: link.groupId,
        groupKey: link.groupKey,
        localDevice: local,
      );
      final group = remoteGroup
          .copyWith(groupKey: link.groupKey)
          .addOrUpdateDevice(local);

      await _credentialStore.save(
        MergedGroupCredentials(
          groupId: group.groupId,
          groupKey: group.groupKey,
          createdAt: group.createdAt,
        ),
      );
      for (final item in group.devices) {
        await _repository.saveDevice(
          item.copyWith(groupId: group.groupId),
        );
      }

      _setState(
        state.copyWith(
          isBusy: false,
          isActive: true,
          group: group,
          localDevice: local,
          devices: _peersOnly(group, local.deviceId),
          clearError: true,
        ),
      );
      if (_autoStartRuntime) await _startRuntime();
      return true;
    } on MergeClientException catch (error) {
      await _credentialStore.clear();
      _setState(
        state.copyWith(isBusy: false, errorMessage: error.message),
      );
      return false;
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] join failed: $error');
      await _credentialStore.clear();
      _setState(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Could not join Merge Space: $error',
        ),
      );
      return false;
    }
  }

  Future<void> addFilesToSpace() async {
    if (!state.hasGroup || state.localDevice == null) return;
    if (state.isBusy) return;

    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.files.isEmpty) {
        _setState(state.copyWith(isBusy: false));
        return;
      }

      for (final picked in result.files) {
        final sourcePath = picked.path;
        if (sourcePath == null) continue;
        final source = File(sourcePath);
        if (!await source.exists()) continue;
        final bytes = await source.readAsBytes();
        final target = await _uniqueRelativePath(picked.name);
        await _storage.writeBytes(target, bytes);
      }

      await _syncService.scanLocal(state.localDevice!.deviceId);
      await refresh();
      _scheduler?.trigger();
      _setState(state.copyWith(isBusy: false));
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] addFiles failed: $error');
      _setState(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Could not add files: $error',
        ),
      );
    }
  }

  Future<void> removeDevice(String deviceId) async {
    final group = state.group;
    if (group == null) return;
    await _repository.removeDevice(deviceId);
    final updated = group.removeDevice(deviceId);
    _peers.remove(deviceId);
    _setState(
      state.copyWith(
        group: updated,
        devices: _peersOnly(updated, state.localDevice?.deviceId ?? ''),
        nearbyPeers: state.nearbyPeers
            .where((peer) => peer.deviceId != deviceId)
            .toList(),
      ),
    );
    await refresh();
  }

  Future<String> _uniqueRelativePath(String rawName) async {
    final segments = rawName.replaceAll('\\', '/').split('/');
    final base = segments.isEmpty ? 'file' : segments.last.trim();
    final safeName = base.isEmpty ? 'file' : base;
    var candidate = safeName;
    if (!await _storage.exists(candidate)) return candidate;

    final dot = safeName.lastIndexOf('.');
    final hasExtension = dot > 0;
    final stem = hasExtension ? safeName.substring(0, dot) : safeName;
    final extension = hasExtension ? safeName.substring(dot) : '';
    var index = 1;
    while (await _storage.exists(candidate)) {
      candidate = '$stem ($index)$extension';
      index++;
    }
    return candidate;
  }

  Future<void> refresh() async {
    final files = await _repository.getAllFiles();
    final conflicts = await _repository.getConflicts();
    final devices = await _repository.getDevices();
    final group = state.group;
    if (_disposed) return;
    _setState(
      state.copyWith(
        files: files,
        conflicts: conflicts,
        devices: group == null
            ? devices
            : devices
                .where((item) => item.deviceId != state.localDevice?.deviceId)
                .toList(),
        group: group?.copyWith(devices: devices),
      ),
    );
  }

  Future<void> syncNow() async {
    if (!state.hasGroup || state.localDevice == null) return;
    if (state.isSyncing) return;

    final peers = _peerEndpoints();
    if (peers.isEmpty) {
      _setState(
        state.copyWith(
          errorMessage: 'No paired device is nearby. Keep both devices on the '
              'same Wi-Fi network.',
        ),
      );
      return;
    }

    _setState(state.copyWith(isSyncing: true, clearError: true));
    try {
      final report = await _syncService.sync(
        group: state.group!,
        localDevice: state.localDevice!,
        peers: peers,
      );
      await refresh();
      _setState(
        state.copyWith(
          isSyncing: false,
          lastSyncedAt: DateTime.now(),
          lastTransferCount: report.transfers,
          lastConflictCount: report.conflicts,
        ),
      );
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] sync failed: $error');
      _setState(
        state.copyWith(
          isSyncing: false,
          errorMessage: 'Sync failed: $error',
        ),
      );
    }
  }

  Future<void> resolveConflict(
    SyncConflict conflict,
    MergeConflictResolution resolution,
  ) async {
    final group = state.group;
    final local = state.localDevice;
    if (group == null || local == null) return;

    MergePeerEndpoint? peer;
    for (final endpoint in _peerEndpoints()) {
      if (endpoint.deviceId == conflict.remoteDeviceId) {
        peer = endpoint;
        break;
      }
    }
    if (peer == null) {
      _setState(
        state.copyWith(
          errorMessage: 'The other device must be nearby to resolve this.',
        ),
      );
      return;
    }

    _setState(state.copyWith(isBusy: true, clearError: true));
    try {
      await _syncService.resolveConflict(
        conflict: conflict,
        resolution: resolution,
        group: group,
        localDevice: local,
        peer: peer,
      );
      await refresh();
      _setState(state.copyWith(isBusy: false));
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] resolve failed: $error');
      _setState(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Could not resolve conflict: $error',
        ),
      );
    }
  }

  Future<void> unpair() async {
    await _stopRuntime();
    await _credentialStore.clear();
    await _repository.clearFiles();
    await _repository.clearDevices();
    await _repository.clearConflicts();
    _peers.clear();
    _setState(
      const MergeSpaceState(isInitialized: true),
    );
  }

  Future<void> _startRuntime() async {
    if (_disposed || !state.hasGroup || state.localDevice == null) return;
    final group = state.group!;
    final local = state.localDevice!;

    _localIp ??= await _resolveLocalIp();

    _server ??= MergeSpaceServer(
      groupProvider: () => state.group,
      onPair: _handlePair,
      buildIndex: () => _syncService.scanLocal(local.deviceId),
      onFileReceived: _handleFileReceived,
      onRemoteDelete: _handleRemoteDelete,
      storage: _storage,
      localDeviceId: () => state.localDevice?.deviceId ?? '',
    );
    final port = await _server!.start();
    _port = port;

    _peerSubscription ??= _discovery.onPeerDiscovered.listen(_handlePeer);
    _peerLostSubscription ??= _discovery.onPeerLost.listen(_handlePeerLost);
    try {
      await _discovery.startBroadcast(
        groupId: group.groupId,
        deviceId: local.deviceId,
        deviceName: local.deviceName,
        platform: local.platform,
        hostIp: _localIp!,
        port: port,
      );
      await _discovery.startDiscovery(groupId: group.groupId);
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] Discovery failed: $error');
    }

    _watcher ??= MergeFolderWatcher(
      storage: _storage,
      onChanged: () => _scheduler?.schedule(),
    );
    await _watcher!.start();

    _scheduler ??= MergeSyncScheduler(
      run: _autoSync,
      onError: (error) {
        debugPrint('[MergeSpaceNotifier] scheduled sync failed: $error');
      },
    );
    _scheduler!.start();
    _updatePairingUri();
  }

  Future<void> _stopRuntime() async {
    _scheduler?.dispose();
    _scheduler = null;
    await _watcher?.stop();
    _watcher = null;
    await _peerSubscription?.cancel();
    _peerSubscription = null;
    await _peerLostSubscription?.cancel();
    _peerLostSubscription = null;
    await _discovery.stopBroadcast();
    await _discovery.stopDiscovery();
    await _server?.stop();
    _server = null;
    _port = null;
  }

  Future<void> _autoSync() async {
    if (_disposed || !state.hasGroup) return;
    if (_peerEndpoints().isEmpty) return;
    await syncNow();
  }

  void _handlePeer(MergePeerAnnouncement announcement) {
    if (announcement.groupId != state.group?.groupId) return;
    _peers[announcement.deviceId] = announcement;
    final nowNearby = _peers.values
        .where((peer) => peer.deviceId != state.localDevice?.deviceId)
        .toList();
    _setState(state.copyWith(nearbyPeers: nowNearby));
    _scheduler?.trigger();
  }

  void _handlePeerLost(String deviceId) {
    if (_peers.remove(deviceId) == null) return;
    _setState(
      state.copyWith(
        nearbyPeers: _peers.values
            .where((peer) => peer.deviceId != state.localDevice?.deviceId)
            .toList(),
      ),
    );
  }

  Future<DeviceGroup> _handlePair(PairedDevice device) async {
    var group = state.group;
    if (group == null) {
      throw StateError('Merge Space is not active');
    }
    final withDevice = group.addOrUpdateDevice(device);
    await _repository.saveDevice(device);
    group = withDevice;
    _setState(
      state.copyWith(
        group: group,
        devices: _peersOnly(group, state.localDevice?.deviceId ?? ''),
      ),
    );
    _scheduler?.trigger();
    return group;
  }

  Future<void> _handleFileReceived(MergeSpaceFile file) async {
    await _repository.saveFile(file);
    await refresh();
  }

  Future<void> _handleRemoteDelete(
    String relativePath,
    String deviceId,
  ) async {
    final local = await _repository.getFile(relativePath);
    if (local != null && !local.isDeleted) {
      await _repository.saveFile(
        local.copyWith(isDeleted: true, baseHash: local.hash),
      );
    }
    await refresh();
  }

  List<MergePeerEndpoint> _peerEndpoints() {
    final localId = state.localDevice?.deviceId;
    final endpoints = <MergePeerEndpoint>[];
    for (final device in state.devices) {
      if (device.deviceId == localId) continue;
      final peer = _peers[device.deviceId];
      if (peer == null) continue;
      endpoints.add(
        MergePeerEndpoint(
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          host: peer.hostIp,
          port: peer.port,
        ),
      );
    }
    return endpoints;
  }

  List<PairedDevice> _peersOnly(DeviceGroup group, String localId) {
    return group.devices.where((device) => device.deviceId != localId).toList()
      ..sort((a, b) => a.deviceName.compareTo(b.deviceName));
  }

  PairedDevice _toPairedDevice(Device device, String groupId) {
    return PairedDevice(
      deviceId: device.id,
      deviceName: device.name,
      platform: device.platform,
      groupId: groupId,
      pairedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }

  Future<String> _resolveLocalIp() async {
    if (kIsWeb) return '127.0.0.1';
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] Could not resolve LAN address: $error');
    }
    return '127.0.0.1';
  }

  void _updatePairingUri() {
    final group = state.group;
    final ip = _localIp;
    final port = _port;
    if (group == null || ip == null || port == null || port <= 0) return;
    try {
      final uri = _pairingService.buildUri(
        group: group,
        hostAddress: ip,
        port: port,
      );
      _setState(state.copyWith(pairingUri: uri));
    } catch (error) {
      debugPrint('[MergeSpaceNotifier] Could not build pairing URI: $error');
    }
  }

  void _setState(MergeSpaceState value) {
    if (_disposed || !mounted) return;
    state = value;
  }

  @override
  void dispose() {
    _disposed = true;
    _peerSubscription?.cancel();
    _peerLostSubscription?.cancel();
    _scheduler?.dispose();
    unawaited(_watcher?.stop());
    unawaited(_server?.stop());
    unawaited(_discovery.dispose());
    super.dispose();
  }
}
