/// Default size of a transfer chunk (1 MB).
const int kDefaultChunkSize = 1024 * 1024;

/// Describes a single contiguous byte range of a file within a resumable
/// transfer.
///
/// Byte ranges follow the HTTP `Content-Range` convention: [startByte] is
/// inclusive and [endByte] is inclusive, so the chunk covers
/// `endByte - startByte + 1` bytes.
class ChunkInfo {
  final int index;
  final int startByte;
  final int endByte;
  final int size;
  final bool received;

  const ChunkInfo({
    required this.index,
    required this.startByte,
    required this.endByte,
    required this.size,
    this.received = false,
  });

  /// Exclusive upper bound, as used by `File.openRead(start, end)`.
  int get endByteExclusive => endByte + 1;

  /// Builds the standard HTTP `Content-Range` header value for this chunk.
  ///
  /// Example: `bytes 0-1048575/5242880`
  String contentRange(int totalBytes) => 'bytes $startByte-$endByte/$totalBytes';

  ChunkInfo copyWith({
    int? index,
    int? startByte,
    int? endByte,
    int? size,
    bool? received,
  }) {
    return ChunkInfo(
      index: index ?? this.index,
      startByte: startByte ?? this.startByte,
      endByte: endByte ?? this.endByte,
      size: size ?? this.size,
      received: received ?? this.received,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startByte': startByte,
      'endByte': endByte,
      'size': size,
      'received': received,
    };
  }

  factory ChunkInfo.fromJson(Map<String, dynamic> json) {
    return ChunkInfo(
      index: json['index'] as int? ?? 0,
      startByte: json['startByte'] as int? ?? 0,
      endByte: json['endByte'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      received: json['received'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkInfo &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          startByte == other.startByte &&
          endByte == other.endByte &&
          size == other.size &&
          received == other.received;

  @override
  int get hashCode =>
      index.hashCode ^
      startByte.hashCode ^
      endByte.hashCode ^
      size.hashCode ^
      received.hashCode;

  @override
  String toString() {
    return 'ChunkInfo(index: $index, range: $startByte-$endByte, size: $size, received: $received)';
  }
}
