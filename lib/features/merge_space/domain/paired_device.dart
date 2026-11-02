enum SyncStatus {
  synced,
  syncing,
  pendingSync,
  offline,
  error;

  static SyncStatus fromName(String? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.pendingSync,
    );
  }
}

/// A device that belongs to the same Merge Space group.
class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String groupId;
  final DateTime pairedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;

  const PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.groupId = '',
    required this.pairedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pendingSync,
  });

  PairedDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? platform,
    String? groupId,
    DateTime? pairedAt,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    SyncStatus? syncStatus,
  }) {
    return PairedDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      groupId: groupId ?? this.groupId,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'groupId': groupId,
      'pairedAt': pairedAt.toIso8601String(),
      if (lastSyncedAt != null)
        'lastSyncedAt': lastSyncedAt!.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory PairedDevice.fromJson(Map<String, dynamic> json) {
    return PairedDevice(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'unknown',
      groupId: json['groupId'] as String? ?? '',
      pairedAt: DateTime.tryParse(json['pairedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairedDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          deviceName == other.deviceName &&
          platform == other.platform &&
          groupId == other.groupId &&
          pairedAt.isAtSameMomentAs(other.pairedAt) &&
          lastSyncedAt == other.lastSyncedAt &&
          syncStatus == other.syncStatus;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      deviceName.hashCode ^
      platform.hashCode ^
      groupId.hashCode ^
      pairedAt.hashCode ^
      lastSyncedAt.hashCode ^
      syncStatus.hashCode;

  @override
  String toString() =>
      'PairedDevice($deviceName, $platform, $syncStatus)';
}

/// The trusted ring of devices sharing one Merge Space.
class DeviceGroup {
  final String groupId;

  /// 256-bit AES key encoded as base64.
  final String groupKey;
  final List<PairedDevice> devices;
  final DateTime createdAt;

  const DeviceGroup({
    required this.groupId,
    required this.groupKey,
    required this.devices,
    required this.createdAt,
  });

  PairedDevice? deviceById(String deviceId) {
    for (final device in devices) {
      if (device.deviceId == deviceId) return device;
    }
    return null;
  }

  DeviceGroup addOrUpdateDevice(PairedDevice device) {
    final updated = List<PairedDevice>.from(devices);
    final index = updated.indexWhere((d) => d.deviceId == device.deviceId);
    if (index >= 0) {
      updated[index] = device;
    } else {
      updated.add(device);
    }
    return copyWith(devices: updated);
  }

  DeviceGroup removeDevice(String deviceId) {
    return copyWith(
      devices: devices.where((d) => d.deviceId != deviceId).toList(),
    );
  }

  DeviceGroup copyWith({
    String? groupId,
    String? groupKey,
    List<PairedDevice>? devices,
    DateTime? createdAt,
  }) {
    return DeviceGroup(
      groupId: groupId ?? this.groupId,
      groupKey: groupKey ?? this.groupKey,
      devices: devices ?? this.devices,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupKey': groupKey,
      'devices': devices.map((d) => d.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    final rawDevices = json['devices'] as List<dynamic>? ?? const [];
    return DeviceGroup(
      groupId: json['groupId'] as String? ?? '',
      groupKey: json['groupKey'] as String? ?? '',
      devices: rawDevices
          .map((d) => PairedDevice.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceGroup &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          groupKey == other.groupKey &&
          createdAt.isAtSameMomentAs(other.createdAt);

  @override
  int get hashCode => groupId.hashCode ^ groupKey.hashCode ^ createdAt.hashCode;

  @override
  String toString() =>
      'DeviceGroup($groupId, ${devices.length} devices)';
}

/// Group credentials as persisted in secure storage.
class MergedGroupCredentials {
  final String groupId;
  final String groupKey;
  final DateTime createdAt;

  const MergedGroupCredentials({
    required this.groupId,
    required this.groupKey,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupKey': groupKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MergedGroupCredentials.fromJson(Map<String, dynamic> json) {
    return MergedGroupCredentials(
      groupId: json['groupId'] as String? ?? '',
      groupKey: json['groupKey'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
