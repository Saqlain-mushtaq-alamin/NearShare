class TransferFile {
  final String name;
  final int sizeInBytes;
  final String mimeType;
  final String localPath;
  final String? savePath;

  const TransferFile({
    required this.name,
    required this.sizeInBytes,
    required this.mimeType,
    required this.localPath,
    this.savePath,
  });

  TransferFile copyWith({
    String? name,
    int? sizeInBytes,
    String? mimeType,
    String? localPath,
    String? savePath,
  }) {
    return TransferFile(
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      savePath: savePath ?? this.savePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sizeInBytes': sizeInBytes,
      'mimeType': mimeType,
      'localPath': localPath,
      if (savePath != null) 'savePath': savePath,
    };
  }

  factory TransferFile.fromJson(Map<String, dynamic> json) {
    return TransferFile(
      name: json['name'] as String? ?? 'unnamed',
      sizeInBytes: json['sizeInBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      localPath: json['localPath'] as String? ?? '',
      savePath: json['savePath'] as String?,
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
          savePath == other.savePath;

  @override
  int get hashCode =>
      name.hashCode ^
      sizeInBytes.hashCode ^
      mimeType.hashCode ^
      localPath.hashCode ^
      savePath.hashCode;

  @override
  String toString() {
    return 'TransferFile(name: $name, size: $sizeInBytes bytes, mime: $mimeType)';
  }
}
