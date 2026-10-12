/// Answer of the receiver to `GET /api/v1/transfer/resume/:transferId/:fileIndex`.
///
/// Tells the sender which chunks it may skip when a transfer is resumed.
class ResumeState {
  final bool known;
  final List<int> receivedChunks;
  final int totalChunksExpected;
  final bool fileComplete;
  final String? savePath;

  const ResumeState({
    required this.known,
    required this.receivedChunks,
    required this.totalChunksExpected,
    this.fileComplete = false,
    this.savePath,
  });

  /// The receiver has no record of this transfer, so everything must be sent.
  const ResumeState.unknown()
      : known = false,
        receivedChunks = const [],
        totalChunksExpected = 0,
        fileComplete = false,
        savePath = null;

  /// Chunk indices still to be transmitted, ascending.
  List<int> get missingChunks {
    final received = receivedChunks.toSet();
    return [
      for (var i = 0; i < totalChunksExpected; i++)
        if (!received.contains(i)) i,
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'known': known,
      'receivedChunks': receivedChunks,
      'totalChunksExpected': totalChunksExpected,
      'fileComplete': fileComplete,
      'savePath': savePath,
    };
  }

  factory ResumeState.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['receivedChunks'] as List<dynamic>? ?? const [];
    final received = rawChunks.map((c) => c as int).toList()..sort();

    return ResumeState(
      known: json['known'] as bool? ?? true,
      receivedChunks: received,
      totalChunksExpected: json['totalChunksExpected'] as int? ?? 0,
      fileComplete: json['fileComplete'] as bool? ?? false,
      savePath: json['savePath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumeState &&
          runtimeType == other.runtimeType &&
          known == other.known &&
          totalChunksExpected == other.totalChunksExpected &&
          fileComplete == other.fileComplete &&
          savePath == other.savePath &&
          _listEquals(receivedChunks, other.receivedChunks);

  @override
  int get hashCode =>
      known.hashCode ^
      totalChunksExpected.hashCode ^
      fileComplete.hashCode ^
      savePath.hashCode ^
      Object.hashAll(receivedChunks);

  @override
  String toString() {
    return 'ResumeState(known: $known, received: $receivedChunks, '
        'total: $totalChunksExpected, complete: $fileComplete)';
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Aggregate resume answer covering every file of a transfer.
class TransferResumeState {
  final bool known;
  final List<ResumeState> files;
  final bool allComplete;

  const TransferResumeState({
    required this.known,
    required this.files,
    required this.allComplete,
  });

  const TransferResumeState.unknown()
      : known = false,
        files = const [],
        allComplete = false;

  factory TransferResumeState.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? const [];
    final files = rawFiles
        .map((f) => ResumeState.fromJson(f as Map<String, dynamic>))
        .toList();
    return TransferResumeState(
      known: json['known'] as bool? ?? true,
      files: files,
      allComplete: json['allComplete'] as bool? ??
          files.every((f) => f.fileComplete),
    );
  }
}
