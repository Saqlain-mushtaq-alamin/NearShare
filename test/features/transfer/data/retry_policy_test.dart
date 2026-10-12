import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/retry_policy.dart';

void main() {
  group('RetryPolicy.delayForAttempt', () {
    const policy = RetryPolicy(
      initialDelay: Duration(milliseconds: 200),
      maxDelay: Duration(seconds: 1),
      multiplier: 2.0,
    );

    test('grows exponentially', () {
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 200));
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 400));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 800));
    });

    test('is capped at maxDelay', () {
      expect(policy.delayForAttempt(10), const Duration(seconds: 1));
      expect(policy.delayForAttempt(1), isNot(const Duration(seconds: 1)));
    });

    test('treats non-positive retry numbers as the first attempt', () {
      expect(policy.delayForAttempt(0), const Duration(milliseconds: 200));
      expect(policy.delayForAttempt(-3), const Duration(milliseconds: 200));
    });
  });

  group('RetryPolicy.run', () {
    List<Duration> recorded = <Duration>[];

    Future<void> recordingSleep(Duration duration) async {
      recorded.add(duration);
    }

    setUp(() {
      recorded = <Duration>[];
    });

    test('returns immediately when the action succeeds', () async {
      final policy = RetryPolicy(sleep: recordingSleep);
      final result = await policy.run(() async => 'ok');
      expect(result, 'ok');
      expect(recorded, isEmpty);
    });

    test('retries until it succeeds and records the backoff delays',
        () async {
      final policy = RetryPolicy(
        maxAttempts: 4,
        initialDelay: const Duration(milliseconds: 10),
        sleep: recordingSleep,
      );

      var attempts = 0;
      final result = await policy.run(() async {
        attempts++;
        if (attempts < 3) throw StateError('try again');
        return attempts;
      });

      expect(result, 3);
      expect(recorded, [
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 20),
      ]);
    });

    test('gives up after maxAttempts and rethrows', () async {
      final policy = RetryPolicy(
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 1),
        sleep: recordingSleep,
      );

      var attempts = 0;
      await expectLater(
        policy.run(() async {
          attempts++;
          throw StateError('always');
        }),
        throwsA(isA<StateError>()),
      );
      expect(attempts, 3);
      expect(recorded, hasLength(2));
    });

    test('retryIf can veto a retry', () async {
      final policy = RetryPolicy(
        maxAttempts: 5,
        sleep: recordingSleep,
      );

      var attempts = 0;
      await expectLater(
        policy.run(
          () async {
            attempts++;
            throw ArgumentError('fatal');
          },
          retryIf: (error, stack) => error is! ArgumentError,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(attempts, 1);
      expect(recorded, isEmpty);
    });

    test('onRetry is invoked before each backoff', () async {
      final policy = RetryPolicy(
        maxAttempts: 2,
        initialDelay: const Duration(milliseconds: 7),
        sleep: recordingSleep,
      );

      final seen = <int>[];
      await expectLater(
        policy.run(
          () async => throw StateError('nope'),
          onRetry: (number, delay, error) => seen.add(number),
        ),
        throwsA(isA<StateError>()),
      );
      expect(seen, [1]);
    });
  });

  group('isConnectionError', () {
    test('matches Dio transport failures', () {
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        ),
        isTrue,
      );
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        isTrue,
      );
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.sendTimeout,
          ),
        ),
        isTrue,
      );
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        isTrue,
      );
    });

    test('does not treat HTTP responses as connection failures', () {
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
          ),
        ),
        isFalse,
      );
      expect(
        isConnectionError(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.cancel,
          ),
        ),
        isFalse,
      );
    });

    test('matches platform socket errors by message', () {
      expect(
        isConnectionError(const SocketExceptionLike('Connection refused')),
        isTrue,
      );
      expect(isConnectionError(StateError('some logic bug')), isFalse);
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike(this.message);
  final String message;
  @override
  String toString() => 'SocketException: $message';
}
