import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/transfer/presentation/device_select_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceSelectScreen Widget Tests', () {
    testWidgets('Renders radar scanning state when device list is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeviceSelectScreen(),
          ),
        ),
      );

      expect(find.text('Select Recipient'), findsOneWidget);
      expect(find.text('Searching for nearby devices\u2026'), findsOneWidget);
    });

    testWidgets('Renders discovered devices and handles device selection', (tester) async {
      final testDevice = Device(
        id: 'peer-dev-1',
        name: 'Pixel 8 Pro',
        platform: 'android',
        ipAddress: '192.168.1.55',
        port: 53317,
        discoveredAt: DateTime.now(),
      );

      final router = GoRouter(
        initialLocation: '/send/select-device',
        routes: [
          GoRoute(
            path: '/send/select-device',
            builder: (context, state) => const DeviceSelectScreen(),
          ),
          GoRoute(
            path: '/send/confirm',
            builder: (context, state) => const Scaffold(body: Text('Confirm Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(discoveryStateProvider.notifier).addSimulatedDevice(testDevice);
              });
              return MaterialApp.router(
                routerConfig: router,
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nearby Devices (1)'), findsOneWidget);
      expect(find.text('Pixel 8 Pro'), findsOneWidget);
      expect(find.text('192.168.1.55:53317'), findsOneWidget);

      // Tap the device card
      await tester.tap(find.text('Pixel 8 Pro'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Screen'), findsOneWidget);
    });
  });
}
