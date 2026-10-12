import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Signature of the function used to wait between retries.
typedef SleepFn = Future<void> Function(Duration duration);

Future<void> _defaultSleep(Duration duration) => Future<void>.delayed(duration);

/// Retries a failing operation with exponential backoff.
///
/// The delay before retry `n` (1-based) is
/// `initialDelay * multiplier^(n-1)` capped at [maxDelay].
class RetryPolicy {
  /// Total number of attempts, including the first one.
  final int maxAttempts;

  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  final SleepFn _sleep;

  const RetryPolicy({
    this.maxAttempts = 4,
    this.initialDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 10),
    this.multiplier = 2.0,
    SleepFn sleep = _defaultSleep,
  }) : _sleep = sleep;

  /// Delay to wait after [retryNumber] consecutive failures.
  ///
  /// [retryNumber] is 1-based: `delayForAttempt(1)` is the first backoff.
  Duration delayForAttempt(int retryNumber) {
    if (retryNumber <= 1) return initialDelay;
    final rawMicros =
        initialDelay.inMicroseconds * pow(multiplier, retryNumber - 1);
    final capped = min(rawMicros.toDouble(), maxDelay.inMicroseconds.toDouble());
    return Duration(microseconds: capped.round());
  }

  /// Runs [action], retrying on failure until [maxAttempts] is reached.
  ///
  /// [retryIf] can veto a retry for non-transient errors. [onRetry] is invoked
  /// before every backoff with the upcoming delay.
  Future<T> run<T>(
    Future<T> Function() action, {
    bool Function(Object error, StackTrace stack)? retryIf,
    void Function(int retryNumber, Duration delay, Object error)? onRetry,
  }) async {
    var failures = 0;
    while (true) {
      try {
        return await action();
      } catch (error, stack) {
        failures++;
        final isLastAttempt = failures >= maxAttempts;
        final allowed = retryIf == null || retryIf(error, stack);
        if (isLastAttempt || !allowed) {
          rethrow;
        }
        final delay = delayForAttempt(failures);
        onRetry?.call(failures, delay, error);
        await _sleep(delay);
      }
    }
  }
}

/// Convenience policy tuned for LAN transfers: a handful of quick retries
/// before surfacing a connection problem to the user.
const RetryPolicy transferRetryPolicy = RetryPolicy();

/// Whether [error] looks like the peer became unreachable.
///
/// Dio transport failures are matched by type; other exceptions are matched by
/// the words they carry so platform-specific socket errors are covered too.
bool isConnectionError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        break;
    }
  }

  final text = error.toString().toLowerCase();
  const keywords = [
    'connection refused',
    'connection reset',
    'connection closed',
    'connection error',
    'failed host lookup',
    'network is unreachable',
    'host unreachable',
    'connection timeout',
    'request timeout',
    'send timeout',
    'receive timeout',
    'socketexception',
    'clientexception',
    'connectionlostexception',
    'econnrefused',
    'econnreset',
    'etimedout',
    'enotfound',
    'no route to host',
  ];
  return keywords.any(text.contains);
}
