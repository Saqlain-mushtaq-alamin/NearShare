import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/merge_crypto.dart';

void main() {
  group('MergeCrypto', () {
    late MergeCrypto crypto;
    late String key;

    setUp(() {
      crypto = MergeCrypto();
      key = MergeCrypto.generateGroupKey();
    });

    test('generates 256-bit base64 keys', () {
      expect(base64Decode(key), hasLength(MergeCrypto.keyLengthBytes));
    });

    test('round-trips arbitrary bytes', () async {
      final data = List<int>.generate(4096, (index) => index % 256);
      final encrypted = await crypto.encrypt(data, groupKey: key);

      expect(encrypted, isNot(equals(data)));
      expect(
        await crypto.decrypt(encrypted, groupKey: key),
        equals(data),
      );
    });

    test('round-trips strings', () async {
      const clear = '{"files":[{"path":"notes/hello world.txt"}]}';
      final encrypted = await crypto.encryptString(clear, groupKey: key);

      expect(await crypto.decryptString(encrypted, groupKey: key), clear);
    });

    test('rejects a payload encrypted with a different key', () async {
      final encrypted = await crypto.encrypt(
        utf8.encode('secret'),
        groupKey: key,
      );
      final otherKey = MergeCrypto.generateGroupKey();

      await expectLater(
        crypto.decrypt(encrypted, groupKey: otherKey),
        throwsA(anything),
      );
    });

    test('rejects truncated payloads', () async {
      await expectLater(
        crypto.decrypt(const [1, 2, 3], groupKey: key),
        throwsFormatException,
      );
    });

    test('fingerprints are stable and key-specific', () {
      expect(
        MergeCrypto.fingerprint(key),
        MergeCrypto.fingerprint(key),
      );
      expect(
        MergeCrypto.fingerprint(key),
        isNot(MergeCrypto.fingerprint(MergeCrypto.generateGroupKey())),
      );
    });
  });
}
