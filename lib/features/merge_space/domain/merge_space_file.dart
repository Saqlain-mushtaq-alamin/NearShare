/// Metadata for a single file inside the Merge Space folder.
///
/// [relativePath] always uses `/` separators so indices produced on Windows and
/// POSIX devices can be compared byte-for-byte.
class MergeSpaceFile {
  final String relativePath;
  final String hash;

  /// Hash both sides agreed on during the last successful sync.
  ///
  /// Used to tell "only this side changed" apart from "both sides changed",
  /// which is what makes conflict detection deterministic.
  final String? baseHash;
  final int sizeBytes;
  final DateTime modifiedAt;
  final bool isDeleted;
  final String originDeviceId;

  const MergeSpaceFile({
    required this.relativePath,
    required this.hash,
    this.baseHash,
    required this.sizeBytes,
    required this.modifiedAt,
    this.isDeleted = false,
    this.originDeviceId = '',
  });

  String get fileName {
    final index = relativePath.lastIndexOf('/');
    return index < 0 ? relativePath : relativePath.substring(index + 1);
  }

  /// Directory portion of [relativePath], or an empty string at the root.
  String get directory {
    final index = relativePath.lastIndexOf('/');
    return index < 0 ? '' : relativePath.substring(0, index);
  }

  String get extension {
    final name = fileName;
    final index = name.lastIndexOf('.');
    return index <= 0 ? '' : name.substring(index);
  }

  MergeSpaceFile copyWith({
    String? relativePath,
    String? hash,
    String? baseHash,
    bool clearBaseHash = false,
    int? sizeBytes,
    DateTime? modifiedAt,
    bool? isDeleted,
    String? originDeviceId,
  }) {
    return MergeSpaceFile(
      relativePath: relativePath ?? this.relativePath,
      hash: hash ?? this.hash,
      baseHash: clearBaseHash ? null : (baseHash ?? this.baseHash),
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      originDeviceId: originDeviceId ?? this.originDeviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relativePath': relativePath,
      'hash': hash,
      if (baseHash != null) 'baseHash': baseHash,
      'sizeBytes': sizeBytes,
      'modifiedAt': modifiedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'originDeviceId': originDeviceId,
    };
  }

  factory MergeSpaceFile.fromJson(Map<String, dynamic> json) {
    return MergeSpaceFile(
      relativePath: json['relativePath'] as String? ?? '',
      hash: json['hash'] as String? ?? '',
      baseHash: json['baseHash'] as String?,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      modifiedAt: DateTime.tryParse(json['modifiedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isDeleted: json['isDeleted'] as bool? ?? false,
      originDeviceId: json['originDeviceId'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeSpaceFile &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          hash == other.hash &&
          baseHash == other.baseHash &&
          sizeBytes == other.sizeBytes &&
          modifiedAt.isAtSameMomentAs(other.modifiedAt) &&
          isDeleted == other.isDeleted &&
          originDeviceId == other.originDeviceId;

  @override
  int get hashCode =>
      relativePath.hashCode ^
      hash.hashCode ^
      baseHash.hashCode ^
      sizeBytes.hashCode ^
      modifiedAt.hashCode ^
      isDeleted.hashCode ^
      originDeviceId.hashCode;

  @override
  String toString() =>
      'MergeSpaceFile($relativePath, hash: $hash, deleted: $isDeleted)';
}
