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

/// UI-facing qualifier layered on top of [TransferStatus].
///
/// A transfer can be `inProgress` while it is reconnecting to the peer, which
/// is not visible from the status alone.
enum TransferPhase {
  /// Normal, uninterrupted transmission.
  normal,

  /// Re-establishing the session and skipping chunks the peer already has.
  resuming,

  /// The peer became unreachable; the transfer continues once it is found.
  connectionLost,
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
  final TransferPhase phase;
  final int? currentChunk;
  final int? totalChunks;

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
    this.phase = TransferPhase.normal,
    this.currentChunk,
    this.totalChunks,
  });

  double get percentage {
    if (totalBytes <= 0) return 0.0;
    final p = bytesTransferred / totalBytes;
    if (p < 0.0) return 0.0;
    if (p > 1.0) return 1.0;
    return p;
  }

  bool get isResuming => phase == TransferPhase.resuming;

  bool get isConnectionLost => phase == TransferPhase.connectionLost;

  /// `Chunk 15/50` when chunk information is known, otherwise `null`.
  ///
  /// [currentChunk] is a 0-based index; the label is 1-based for readability.
  String? get chunkLabel {
    if (currentChunk == null || totalChunks == null) return null;
    return 'Chunk ${currentChunk! + 1}/$totalChunks';
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
    TransferPhase? phase,
    int? currentChunk,
    int? totalChunks,
    bool clearCurrentFileName = false,
    bool clearErrorMessage = false,
    bool clearCurrentChunk = false,
    bool clearTotalChunks = false,
  }) {
    return TransferProgress(
      transferId: transferId ?? this.transferId,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBps: speedBps ?? this.speedBps,
      status: status ?? this.status,
      currentFileName: clearCurrentFileName
          ? null
          : (currentFileName ?? this.currentFileName),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      phase: phase ?? this.phase,
      currentChunk:
          clearCurrentChunk ? null : (currentChunk ?? this.currentChunk),
      totalChunks: clearTotalChunks ? null : (totalChunks ?? this.totalChunks),
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
      'phase': phase.name,
      if (currentFileName != null) 'currentFileName': currentFileName,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (currentChunk != null) 'currentChunk': currentChunk,
      if (totalChunks != null) 'totalChunks': totalChunks,
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
      phase: TransferPhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => TransferPhase.normal,
      ),
      currentChunk: json['currentChunk'] as int?,
      totalChunks: json['totalChunks'] as int?,
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
          errorMessage == other.errorMessage &&
          phase == other.phase &&
          currentChunk == other.currentChunk &&
          totalChunks == other.totalChunks;

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
      errorMessage.hashCode ^
      phase.hashCode ^
      currentChunk.hashCode ^
      totalChunks.hashCode;

  @override
  String toString() {
    return 'TransferProgress($status: ${(percentage * 100).toStringAsFixed(1)}%, file $currentFileIndex/$totalFiles, $speedFormatted, ETA: $etaFormatted)';
  }
}
