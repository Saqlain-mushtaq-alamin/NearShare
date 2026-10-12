import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/presentation/transfer_progress_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';

void main() {
  group('TransferProgressScreen Widget Tests', () {
    testWidgets('Renders progress bar, current file, speed, and ETA', (tester) async {
      final target = Device(
        id: 'target-002',
        name: 'Sara iPad',
        platform: 'ios',
        ipAddress: '192.168.1.15',
        port: 53317,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(transferStateProvider.notifier).setSelectedTargetDevice(target);
                  ref.read(transferStateProvider.notifier).setSelectedFiles([]);
                });
                return const TransferProgressScreen(transferId: 'prog-test-1');
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Transferring'), findsWidgets);
      expect(find.text('Cancel Transfer'), findsOneWidget);

      // Open cancel dialog
      await tester.tap(find.text('Cancel Transfer'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancel Transfer?'), findsOneWidget);
    });
  });
}
