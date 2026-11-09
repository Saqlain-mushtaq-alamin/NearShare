import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/chunk_info.dart';

void main() {
  group('ChunkInfo', () {
    test('default chunk size is 1 MB', () {
      expect(kDefaultChunkSize, 1024 * 1024);
    });

    test('endByte is inclusive and endByteExclusive is one past the end',
        () {
      const chunk = ChunkInfo(index: 3, startByte: 10, endByte: 19, size: 10);
      expect(chunk.endByteExclusive, 20);
      expect(chunk.size, chunk.endByte - chunk.startByte + 1);
    });

    test('contentRange builds the HTTP Content-Range value', () {
      const chunk = ChunkInfo(
        index: 0,
        startByte: 0,
        endByte: 1048575,
        size: 1048576,
      );
      expect(chunk.contentRange(5242880), 'bytes 0-1048575/5242880');
    });

    test('json round trip preserves every field', () {
      const chunk = ChunkInfo(
        index: 2,
        startByte: 20,
        endByte: 29,
        size: 10,
        received: true,
      );
      expect(ChunkInfo.fromJson(chunk.toJson()), chunk);
    });

    test('copyWith overrides only the requested fields', () {
      const chunk = ChunkInfo(index: 1, startByte: 0, endByte: 9, size: 10);
      final updated = chunk.copyWith(received: true);
      expect(updated.index, 1);
      expect(updated.startByte, 0);
      expect(updated.received, isTrue);
    });

    test('equality distinguishes different ranges', () {
      const a = ChunkInfo(index: 0, startByte: 0, endByte: 9, size: 10);
      const b = ChunkInfo(index: 1, startByte: 10, endByte: 19, size: 10);
      expect(a == b, isFalse);
      expect(a, a);
    });
  });
}
