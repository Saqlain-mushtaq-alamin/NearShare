import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/data/connection_monitor.dart';

void main() {
  group('ConnectionMonitor', () {
    late Device target;
    late bool reachable;
    late int probeCalls;
    late ConnectionMonitor monitor;

    setUp(() {
      reachable = true;
      probeCalls = 0;
      monitor = ConnectionMonitor(
        probe: (device, transferId) async {
          probeCalls++;
          return reachable;
        },
        interval: const Duration(hours: 1),
        failureThreshold: 2,
      );
      target = Device(
        id: 'peer-1',
        name: 'Peer',
        platform: 'android',
        ipAddress: '127.0.0.1',
        port: 53317,
        discoveredAt: DateTime.now(),
      );
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('a single failed probe is not enough to declare a loss', () async {
      final events = <ConnectionEvent>[];
      final sub = monitor.onEvents.listen(events.add);

      monitor.watch(target: target, transferId: 't1');
      reachable = false;
      await monitor.heartbeatNow('t1');

      expect(monitor.consecutiveFailuresFor('t1'), 1);
      expect(monitor.isLost('t1'), isFalse);
      expect(events, isEmpty);

      await sub.cancel();
    });

    test('failureThreshold consecutive failures emit a lost event', () async {
      final events = <ConnectionEvent>[];
      final sub = monitor.onEvents.listen(events.add);

      monitor.watch(target: target, transferId: 't1');
      reachable = false;
      await monitor.heartbeatNow('t1');
      await monitor.heartbeatNow('t1');

      expect(monitor.isLost('t1'), isTrue);
      expect(events.map((e) => e.kind), [ConnectionEventKind.lost]);

      await sub.cancel();
    });

    test('a successful probe after a drop emits a restored event', () async {
      final events = <ConnectionEvent>[];
      final sub = monitor.onEvents.listen(events.add);

      monitor.watch(target: target, transferId: 't1');
      reachable = false;
      await monitor.heartbeatNow('t1');
      await monitor.heartbeatNow('t1');

      reachable = true;
      await monitor.heartbeatNow('t1');

      expect(monitor.isLost('t1'), isFalse);
      expect(
        events.map((e) => e.kind),
        [ConnectionEventKind.lost, ConnectionEventKind.restored],
      );

      await sub.cancel();
    });

    test('a throwing probe counts as a failure', () async {
      await monitor.dispose();
      monitor = ConnectionMonitor(
        probe: (device, transferId) async => throw StateError('boom'),
        interval: const Duration(hours: 1),
        failureThreshold: 1,
      );

      final events = <ConnectionEvent>[];
      final sub = monitor.onEvents.listen(events.add);

      monitor.watch(target: target, transferId: 't2');
      await monitor.heartbeatNow('t2');

      expect(monitor.isLost('t2'), isTrue);
      expect(events.single.kind, ConnectionEventKind.lost);

      await sub.cancel();
    });

    test('stop removes the watch so further probes are skipped', () async {
      monitor.watch(target: target, transferId: 't1');
      expect(monitor.isWatching('t1'), isTrue);

      monitor.stop('t1');
      expect(monitor.isWatching('t1'), isFalse);

      final before = probeCalls;
      await monitor.heartbeatNow('t1');
      expect(probeCalls, before);
    });

    test('watching the same id twice keeps a single timer', () async {
      monitor.watch(target: target, transferId: 't1');
      monitor.watch(target: target, transferId: 't1');
      expect(monitor.isWatching('t1'), isTrue);
      expect(probeCalls, 0);
    });
  });
}
