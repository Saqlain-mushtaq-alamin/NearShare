import 'merge_space_file.dart';

/// A file that was independently modified on two devices since the last sync.
class SyncConflict {
  final int? id;
  final String relativePath;
  final MergeSpaceFile localVersion;
  final MergeSpaceFile remoteVersion;
  final String remoteDeviceId;
  final DateTime detectedAt;
  final bool resolved;

  const SyncConflict({
    this.id,
    required this.relativePath,
    required this.localVersion,
    required this.remoteVersion,
    required this.remoteDeviceId,
    required this.detectedAt,
    this.resolved = false,
  });

  SyncConflict copyWith({
    int? id,
    String? relativePath,
    MergeSpaceFile? localVersion,
    MergeSpaceFile? remoteVersion,
    String? remoteDeviceId,
    DateTime? detectedAt,
    bool? resolved,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      relativePath: relativePath ?? this.relativePath,
      localVersion: localVersion ?? this.localVersion,
      remoteVersion: remoteVersion ?? this.remoteVersion,
      remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
      detectedAt: detectedAt ?? this.detectedAt,
      resolved: resolved ?? this.resolved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relativePath': relativePath,
      'localVersion': localVersion.toJson(),
      'remoteVersion': remoteVersion.toJson(),
      'remoteDeviceId': remoteDeviceId,
      'detectedAt': detectedAt.toIso8601String(),
      'resolved': resolved,
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as int?,
      relativePath: json['relativePath'] as String? ?? '',
      localVersion: MergeSpaceFile.fromJson(
        (json['localVersion'] as Map<String, dynamic>?) ?? const {},
      ),
      remoteVersion: MergeSpaceFile.fromJson(
        (json['remoteVersion'] as Map<String, dynamic>?) ?? const {},
      ),
      remoteDeviceId: json['remoteDeviceId'] as String? ?? '',
      detectedAt: DateTime.tryParse(json['detectedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      resolved: json['resolved'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncConflict &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          relativePath == other.relativePath &&
          localVersion == other.localVersion &&
          remoteVersion == other.remoteVersion &&
          remoteDeviceId == other.remoteDeviceId &&
          detectedAt.isAtSameMomentAs(other.detectedAt) &&
          resolved == other.resolved;

  @override
  int get hashCode =>
      id.hashCode ^
      relativePath.hashCode ^
      localVersion.hashCode ^
      remoteVersion.hashCode ^
      remoteDeviceId.hashCode ^
      detectedAt.hashCode ^
      resolved.hashCode;

  @override
  String toString() =>
      'SyncConflict($relativePath, remote: $remoteDeviceId)';
}
