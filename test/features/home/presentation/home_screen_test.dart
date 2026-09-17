import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/data/mdns_discovery_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/home/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen renders AppBar, Local Device Identity, and Discovery list', (tester) async {
    final local = Device(
      id: 'local-1',
      name: 'My Test Phone',
      platform: 'android',
      ipAddress: '192.168.1.10',
      port: 53317,
      discoveredAt: DateTime(2026, 1, 1),
    );

    final state = DiscoveryState(
      status: DiscoveryStatus.scanning,
      isBroadcasting: true,
      localDevice: local,
      devices: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryStateProvider.overrideWith(
            (ref) => _StaticHomeDiscoveryNotifier(state),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NearShare'), findsOneWidget);
    expect(find.text('This Device'), findsOneWidget);
    expect(find.text('My Test Phone'), findsOneWidget);
    expect(find.text('Visible'), findsOneWidget);
    expect(find.text('Nearby Devices'), findsOneWidget);
  });
}

class _StaticHomeDiscoveryNotifier extends DiscoveryNotifier {
  _StaticHomeDiscoveryNotifier(DiscoveryState initialState)
      : super(DeviceIdentityService(), _NoOpHomeMdnsService()) {
    state = initialState;
  }
}

class _NoOpHomeMdnsService extends Fake implements MdnsDiscoveryService {
  @override
  Stream<Device> get onDeviceDiscovered => const Stream.empty();

  @override
  Stream<String> get onDeviceLost => const Stream.empty();

  @override
  bool get isBroadcasting => false;

  @override
  bool get isScanning => false;

  @override
  Future<void> startBroadcast({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int port,
  }) async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> dispose() async {}
}
