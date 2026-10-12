enum TransferStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  failed,
  cancelled;

  bool get isFinished =>
      this == TransferStatus.completed ||
      this == TransferStatus.failed ||
      this == TransferStatus.cancelled ||
      this == TransferStatus.rejected;
}

class TransferProgress {
  final String transferId;
  final int currentFileIndex;
  final int totalFiles;
  final int bytesTransferred;
  final int totalBytes;
  final double speedBps; // bytes per second
  final TransferStatus status;
  final String? currentFileName;
  final String? errorMessage;

  const TransferProgress({
    required this.transferId,
    required this.currentFileIndex,
    required this.totalFiles,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.speedBps,
    required this.status,
    this.currentFileName,
    this.errorMessage,
  });

  double get percentage {
    if (totalBytes <= 0) return 0.0;
    final p = bytesTransferred / totalBytes;
    if (p < 0.0) return 0.0;
    if (p > 1.0) return 1.0;
    return p;
  }

  String get speedFormatted {
    if (speedBps <= 0) return '0 B/s';
    if (speedBps < 1024) return '${speedBps.toStringAsFixed(0)} B/s';
    if (speedBps < 1024 * 1024) {
      return '${(speedBps / 1024).toStringAsFixed(1)} KB/s';
    }
    if (speedBps < 1024 * 1024 * 1024) {
      return '${(speedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBps / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
  }

  String get etaFormatted {
    if (status == TransferStatus.completed) return '00:00';
    if (speedBps <= 0 || totalBytes <= bytesTransferred) return '--:--';
    final remainingBytes = totalBytes - bytesTransferred;
    final secondsRemaining = (remainingBytes / speedBps).round();
    if (secondsRemaining < 0) return '00:00';
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  TransferProgress copyWith({
    String? transferId,
    int? currentFileIndex,
    int? totalFiles,
    int? bytesTransferred,
    int? totalBytes,
    double? speedBps,
    TransferStatus? status,
    String? currentFileName,
    String? errorMessage,
  }) {
    return TransferProgress(
      transferId: transferId ?? this.transferId,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBps: speedBps ?? this.speedBps,
      status: status ?? this.status,
      currentFileName: currentFileName ?? this.currentFileName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'currentFileIndex': currentFileIndex,
      'totalFiles': totalFiles,
      'bytesTransferred': bytesTransferred,
      'totalBytes': totalBytes,
      'speedBps': speedBps,
      'status': status.name,
      if (currentFileName != null) 'currentFileName': currentFileName,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory TransferProgress.fromJson(Map<String, dynamic> json) {
    return TransferProgress(
      transferId: json['transferId'] as String? ?? '',
      currentFileIndex: json['currentFileIndex'] as int? ?? 0,
      totalFiles: json['totalFiles'] as int? ?? 0,
      bytesTransferred: json['bytesTransferred'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      speedBps: (json['speedBps'] as num?)?.toDouble() ?? 0.0,
      status: TransferStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      currentFileName: json['currentFileName'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferProgress &&
          runtimeType == other.runtimeType &&
          transferId == other.transferId &&
          currentFileIndex == other.currentFileIndex &&
          totalFiles == other.totalFiles &&
          bytesTransferred == other.bytesTransferred &&
          totalBytes == other.totalBytes &&
          speedBps == other.speedBps &&
          status == other.status &&
          currentFileName == other.currentFileName &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      transferId.hashCode ^
      currentFileIndex.hashCode ^
      totalFiles.hashCode ^
      bytesTransferred.hashCode ^
      totalBytes.hashCode ^
      speedBps.hashCode ^
      status.hashCode ^
      currentFileName.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'TransferProgress($status: ${(percentage * 100).toStringAsFixed(1)}%, file $currentFileIndex/$totalFiles, $speedFormatted, ETA: $etaFormatted)';
  }
}
