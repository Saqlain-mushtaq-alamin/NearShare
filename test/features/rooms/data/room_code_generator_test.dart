import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/data/room_code_generator.dart';

class _SequenceRandom implements Random {
  final List<int> values;
  int _index = 0;

  _SequenceRandom(this.values);

  @override
  int nextInt(int max) {
    final value = values[_index % values.length];
    _index++;
    return value % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  group('RoomCodeGenerator', () {
    test('always generates exactly six numeric digits', () {
      final generator = RoomCodeGenerator();
      for (var i = 0; i < 200; i++) {
        final code = generator.generate();
        expect(code, hasLength(6));
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
      }
    });

    test('validates six-digit codes only', () {
      expect(RoomCodeGenerator.isValid('123456'), isTrue);
      expect(RoomCodeGenerator.isValid('000000'), isTrue);
      expect(RoomCodeGenerator.isValid('12345'), isFalse);
      expect(RoomCodeGenerator.isValid('1234567'), isFalse);
      expect(RoomCodeGenerator.isValid('12a456'), isFalse);
      expect(RoomCodeGenerator.isValid(''), isFalse);
    });

    test('regenerates when the first candidate collides', () {
      final generator = RoomCodeGenerator(random: _SequenceRandom([1, 2]));
      final code = generator.generate(isTaken: (candidate) => candidate == '000001');
      expect(code, '000002');
    });

    test('throws when no unique code can be found', () {
      final generator = RoomCodeGenerator(random: _SequenceRandom([7]));
      expect(
        () => generator.generate(isTaken: (_) => true),
        throwsStateError,
      );
    });
  });
}
