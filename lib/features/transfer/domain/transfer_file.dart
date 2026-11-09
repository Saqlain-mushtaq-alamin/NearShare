class TransferFile {
  final String name;
  final int sizeInBytes;
  final String mimeType;
  final String localPath;
  final String? savePath;
  final String? sha256;

  const TransferFile({
    required this.name,
    required this.sizeInBytes,
    required this.mimeType,
    required this.localPath,
    this.savePath,
    this.sha256,
  });

  TransferFile copyWith({
    String? name,
    int? sizeInBytes,
    String? mimeType,
    String? localPath,
    String? savePath,
    String? sha256,
  }) {
    return TransferFile(
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      savePath: savePath ?? this.savePath,
      sha256: sha256 ?? this.sha256,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sizeInBytes': sizeInBytes,
      'mimeType': mimeType,
      'localPath': localPath,
      if (savePath != null) 'savePath': savePath,
      if (sha256 != null) 'sha256': sha256,
    };
  }

  factory TransferFile.fromJson(Map<String, dynamic> json) {
    return TransferFile(
      name: json['name'] as String? ?? 'unnamed',
      sizeInBytes: json['sizeInBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      localPath: json['localPath'] as String? ?? '',
      savePath: json['savePath'] as String?,
      sha256: json['sha256'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferFile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          sizeInBytes == other.sizeInBytes &&
          mimeType == other.mimeType &&
          localPath == other.localPath &&
          savePath == other.savePath &&
          sha256 == other.sha256;

  @override
  int get hashCode =>
      name.hashCode ^
      sizeInBytes.hashCode ^
      mimeType.hashCode ^
      localPath.hashCode ^
      savePath.hashCode ^
      sha256.hashCode;

  @override
  String toString() {
    return 'TransferFile(name: $name, size: $sizeInBytes bytes, mime: $mimeType)';
  }
}
