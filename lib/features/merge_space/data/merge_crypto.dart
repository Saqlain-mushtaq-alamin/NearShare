import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as sha;
import 'package:cryptography/cryptography.dart';

/// AES-256-GCM helper for every Merge Space payload.
///
/// Wire format is `nonce (12 bytes) || ciphertext || mac (16 bytes)`, which
/// keeps encrypted files self-describing and independent of any transport.
class MergeCrypto {
  static const int keyLengthBytes = 32;
  static const int nonceLengthBytes = 12;
  static const int macLengthBytes = 16;

  final AesGcm _algorithm = AesGcm.with256bits();

  static String generateGroupKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(keyLengthBytes, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Non-reversible fingerprint used to prove knowledge of the group key
  /// during pairing without sending the key itself.
  static String fingerprint(String groupKey) {
    return sha.sha256.convert(base64Decode(groupKey)).toString();
  }

  SecretKey keyFromBase64(String encoded) {
    final bytes = base64Decode(encoded);
    if (bytes.length != keyLengthBytes) {
      throw ArgumentError.value(
        encoded,
        'groupKey',
        'AES-256 keys must be $keyLengthBytes bytes',
      );
    }
    return SecretKey(bytes);
  }

  Future<Uint8List> encrypt(
    List<int> plaintext, {
    required String groupKey,
    List<int>? nonce,
  }) async {
    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: keyFromBase64(groupKey),
      nonce: nonce,
    );
    final builder = BytesBuilder(copy: false)
      ..add(box.nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return builder.takeBytes();
  }

  Future<Uint8List> decrypt(
    List<int> payload, {
    required String groupKey,
  }) async {
    if (payload.length < nonceLengthBytes + macLengthBytes) {
      throw const FormatException('Encrypted payload is too short');
    }
    final nonce = payload.sublist(0, nonceLengthBytes);
    final macStart = payload.length - macLengthBytes;
    final cipherText = payload.sublist(nonceLengthBytes, macStart);
    final mac = Mac(payload.sublist(macStart));

    final clear = await _algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: keyFromBase64(groupKey),
    );
    return Uint8List.fromList(clear);
  }

  Future<String> encryptString(
    String plaintext, {
    required String groupKey,
  }) async {
    final bytes = await encrypt(
      utf8.encode(plaintext),
      groupKey: groupKey,
    );
    return base64Encode(bytes);
  }

  Future<String> decryptString(
    String payload, {
    required String groupKey,
  }) async {
    final bytes = await decrypt(
      base64Decode(payload),
      groupKey: groupKey,
    );
    return utf8.decode(bytes);
  }
}
