import '../data/merge_discovery_service.dart';
import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import '../domain/sync_conflict.dart';

class MergeSpaceState {
  final bool isInitialized;
  final bool isBusy;
  final bool isSyncing;
  final bool isActive;
  final DeviceGroup? group;
  final PairedDevice? localDevice;
  final List<PairedDevice> devices;
  final List<MergeSpaceFile> files;
  final List<SyncConflict> conflicts;
  final List<MergePeerAnnouncement> nearbyPeers;
  final String? pairingUri;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final int lastTransferCount;
  final int lastConflictCount;

  const MergeSpaceState({
    this.isInitialized = false,
    this.isBusy = false,
    this.isSyncing = false,
    this.isActive = false,
    this.group,
    this.localDevice,
    this.devices = const [],
    this.files = const [],
    this.conflicts = const [],
    this.nearbyPeers = const [],
    this.pairingUri,
    this.errorMessage,
    this.lastSyncedAt,
    this.lastTransferCount = 0,
    this.lastConflictCount = 0,
  });

  bool get hasGroup => group != null && group!.groupId.isNotEmpty;

  bool get hasNearbyPeers => nearbyPeers.isNotEmpty;

  int get fileCount => files.where((file) => !file.isDeleted).length;

  int get totalBytes => files
      .where((file) => !file.isDeleted)
      .fold<int>(0, (sum, file) => sum + file.sizeBytes);

  int get conflictCount => conflicts.where((c) => !c.resolved).length;

  MergeSpaceState copyWith({
    bool? isInitialized,
    bool? isBusy,
    bool? isSyncing,
    bool? isActive,
    DeviceGroup? group,
    PairedDevice? localDevice,
    List<PairedDevice>? devices,
    List<MergeSpaceFile>? files,
    List<SyncConflict>? conflicts,
    List<MergePeerAnnouncement>? nearbyPeers,
    String? pairingUri,
    String? errorMessage,
    DateTime? lastSyncedAt,
    int? lastTransferCount,
    int? lastConflictCount,
    bool clearGroup = false,
    bool clearPairingUri = false,
    bool clearError = false,
    bool clearLastSyncedAt = false,
  }) {
    return MergeSpaceState(
      isInitialized: isInitialized ?? this.isInitialized,
      isBusy: isBusy ?? this.isBusy,
      isSyncing: isSyncing ?? this.isSyncing,
      isActive: clearGroup ? false : (isActive ?? this.isActive),
      group: clearGroup ? null : (group ?? this.group),
      localDevice: clearGroup ? null : (localDevice ?? this.localDevice),
      devices: clearGroup ? const [] : (devices ?? this.devices),
      files: clearGroup ? const [] : (files ?? this.files),
      conflicts: clearGroup ? const [] : (conflicts ?? this.conflicts),
      nearbyPeers:
          clearGroup ? const [] : (nearbyPeers ?? this.nearbyPeers),
      pairingUri:
          clearPairingUri ? null : (pairingUri ?? this.pairingUri),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      lastTransferCount: lastTransferCount ?? this.lastTransferCount,
      lastConflictCount: lastConflictCount ?? this.lastConflictCount,
    );
  }
}
