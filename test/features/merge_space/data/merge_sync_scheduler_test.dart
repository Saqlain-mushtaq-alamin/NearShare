import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/merge_sync_scheduler.dart';

void main() {
  testWidgets('debounces bursts of file changes', (tester) async {
    var runs = 0;
    final scheduler = MergeSyncScheduler(
      run: () async => runs++,
      debounce: const Duration(seconds: 2),
      interval: const Duration(hours: 1),
    );

    scheduler.schedule();
    await tester.pump(const Duration(seconds: 1));
    scheduler.schedule();
    await tester.pump(const Duration(seconds: 1));

    expect(runs, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(runs, 1);

    scheduler.dispose();
  });

  testWidgets('coalesces triggers while a sync is in flight', (tester) async {
    var runs = 0;
    final first = Completer<void>();
    final scheduler = MergeSyncScheduler(
      run: () {
        runs++;
        return runs == 1 ? first.future : Future<void>.value();
      },
      debounce: const Duration(milliseconds: 10),
      interval: const Duration(hours: 1),
    );

    scheduler.trigger();
    await tester.pump();
    scheduler.trigger();
    scheduler.trigger();

    expect(runs, 1);

    first.complete();
    await tester.pump();
    await tester.pump();

    expect(runs, 2);

    scheduler.dispose();
  });

  testWidgets('periodic interval checks for nearby peers', (tester) async {
    var runs = 0;
    final scheduler = MergeSyncScheduler(
      run: () async => runs++,
      debounce: const Duration(hours: 1),
      interval: const Duration(minutes: 2),
    );

    scheduler.start();
    await tester.pump(const Duration(minutes: 2));
    await tester.pump();

    expect(runs, 1);

    scheduler.dispose();
  });
}
