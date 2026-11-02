import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounces file-system changes and prevents overlapping sync passes.
class MergeSyncScheduler {
  static const Duration defaultDebounce = Duration(seconds: 2);
  static const Duration defaultInterval = Duration(minutes: 5);

  final Future<void> Function() _run;
  final void Function(Object error)? onError;
  final Duration debounce;
  final Duration interval;

  Timer? _debounceTimer;
  Timer? _intervalTimer;
  Future<void>? _inFlight;
  bool _pending = false;
  bool _disposed = false;

  MergeSyncScheduler({
    required Future<void> Function() run,
    this.onError,
    this.debounce = defaultDebounce,
    this.interval = defaultInterval,
  }) : _run = run;

  bool get isRunning => _inFlight != null;

  void start() {
    if (_disposed) return;
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(interval, (_) => trigger());
  }

  /// Called whenever the local folder changes.
  void schedule() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, trigger);
  }

  /// Runs a sync immediately, coalescing with any pass already in progress.
  void trigger() {
    if (_disposed) return;
    if (_inFlight != null) {
      _pending = true;
      return;
    }

    final future = _run()
        .catchError((Object error, StackTrace stack) {
          debugPrint('[MergeSyncScheduler] Sync failed: $error\n$stack');
          onError?.call(error);
        })
        .whenComplete(() {
          _inFlight = null;
          if (_pending && !_disposed) {
            _pending = false;
            trigger();
          }
        });
    _inFlight = future;
  }

  Future<void> runNow() async {
    if (_disposed) return;
    _debounceTimer?.cancel();
    trigger();
    await _inFlight;
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _intervalTimer?.cancel();
  }
}
