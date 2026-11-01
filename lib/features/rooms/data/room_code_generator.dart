import 'dart:math';

/// Generates the 6-digit numeric codes used to join a room.
class RoomCodeGenerator {
  static const int codeLength = 6;
  static const int _maxValue = 999999;
  static final RegExp _validCode = RegExp(r'^\d{6}$');

  final Random _random;

  RoomCodeGenerator({Random? random}) : _random = random ?? Random.secure();

  /// A strictly numeric, zero-padded 6-digit code.
  ///
  /// When [isTaken] rejects a code the generator retries a bounded number of
  /// times, which keeps a collision from ever escaping as a duplicate room.
  String generate({bool Function(String code)? isTaken}) {
    const maxAttempts = 1000;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code =
          _random.nextInt(_maxValue + 1).toString().padLeft(codeLength, '0');
      if (isTaken == null || !isTaken(code)) return code;
    }
    throw StateError('Unable to generate a unique room code');
  }

  static bool isValid(String code) => _validCode.hasMatch(code);
}
