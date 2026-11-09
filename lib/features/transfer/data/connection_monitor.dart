import 'dart:async';

import '../../discovery/domain/device.dart';

/// Signature of the health check used by [ConnectionMonitor].
typedef ConnectionProbe = Future<bool> Function(Device target, String transferId);

enum ConnectionEventKind {
  /// First successful heartbeat after a drop.
  restored,

  /// The peer stopped answering and the transfer should pause.
  lost,
}

class ConnectionEvent {
  final String transferId;
  final ConnectionEventKind kind;
  final DateTime at;

  const ConnectionEvent({
    required this.transferId,
    required this.kind,
    required this.at,
  });

  @override
  String toString() => 'ConnectionEvent($transferId, $kind)';
}

class _Watch {
  final Device target;
  Timer? timer;
  bool inFlight = false;
  int consecutiveFailures = 0;
  bool isLost = false;

  _Watch(this.target);
}

/// Actively monitors reachability of the peer while a transfer is running.
///
/// A periodic heartbeat is sent to the receiver; once [failureThreshold]
/// consecutive heartbeats fail a `lost` event is emitted so the transfer can be
/// paused and later resumed when the device shows up again.
class ConnectionMonitor {
  final ConnectionProbe probe;
  final Duration interval;
  final int failureThreshold;

  final Map<String, _Watch> _watches = {};
  final StreamController<ConnectionEvent> _events =
      StreamController<ConnectionEvent>.broadcast();

  bool _disposed = false;

  ConnectionMonitor({
    required this.probe,
    this.interval = const Duration(seconds: 3),
    this.failureThreshold = 2,
  });

  Stream<ConnectionEvent> get onEvents => _events.stream;

  bool isWatching(String transferId) => _watches.containsKey(transferId);

  int consecutiveFailuresFor(String transferId) =>
      _watches[transferId]?.consecutiveFailures ?? 0;

  bool isLost(String transferId) => _watches[transferId]?.isLost ?? false;

  /// Starts heartbeating the peer for [transferId].
  void watch({required Device target, required String transferId}) {
    if (_disposed) return;
    final existing = _watches[transferId];
    if (existing != null) {
      if (existing.target != target) {
        _watches[transferId] = _Watch(target)
          ..isLost = existing.isLost
          ..consecutiveFailures = existing.consecutiveFailures;
        _startTimer(transferId);
      }
      return;
    }

    _watches[transferId] = _Watch(target);
    _startTimer(transferId);
  }

  void stop(String transferId) {
    _watches.remove(transferId)?.timer?.cancel();
  }

  /// Runs a heartbeat immediately instead of waiting for the next tick.
  Future<void> heartbeatNow(String transferId) => _tick(transferId);

  void _startTimer(String transferId) {
    final watch = _watches[transferId];
    if (watch == null) return;
    watch.timer?.cancel();
    watch.timer = Timer.periodic(interval, (_) {
      unawaited(_tick(transferId));
    });
  }

  Future<void> _tick(String transferId) async {
    if (_disposed) return;
    final watch = _watches[transferId];
    if (watch == null || watch.inFlight) return;

    watch.inFlight = true;
    var reachable = false;
    try {
      reachable = await probe(watch.target, transferId);
    } catch (_) {
      reachable = false;
    } finally {
      watch.inFlight = false;
    }

    if (_disposed || !_watches.containsKey(transferId)) return;

    if (reachable) {
      final wasLost = watch.isLost;
      watch.consecutiveFailures = 0;
      watch.isLost = false;
      if (wasLost) {
        _events.add(
          ConnectionEvent(
            transferId: transferId,
            kind: ConnectionEventKind.restored,
            at: DateTime.now(),
          ),
        );
      }
      return;
    }

    watch.consecutiveFailures++;
    if (!watch.isLost && watch.consecutiveFailures >= failureThreshold) {
      watch.isLost = true;
      _events.add(
        ConnectionEvent(
          transferId: transferId,
          kind: ConnectionEventKind.lost,
          at: DateTime.now(),
        ),
      );
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final watch in _watches.values) {
      watch.timer?.cancel();
    }
    _watches.clear();
    await _events.close();
  }
}
