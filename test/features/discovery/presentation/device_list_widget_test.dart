import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/discovery/data/mdns_discovery_service.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/discovery/domain/discovery_state.dart';
import 'package:nearshare/features/discovery/presentation/device_list_widget.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(DiscoveryState state, {ValueChanged<Device>? onSelected}) {
    return ProviderScope(
      overrides: [
        discoveryStateProvider.overrideWith(
          (ref) => _StaticDiscoveryNotifier(state),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DeviceListWidget(onDeviceSelected: onSelected),
        ),
      ),
    );
  }

  testWidgets('Renders scanning empty state when no devices are present', (tester) async {
    const state = DiscoveryState(
      status: DiscoveryStatus.scanning,
      devices: [],
    );

    await tester.pumpWidget(createTestWidget(state));
    await tester.pump();

    expect(find.text('Nearby Devices'), findsOneWidget);
    expect(find.text('Scanning local Wi-Fi...'), findsOneWidget);
  });

  testWidgets('Renders idle empty state when scanning is paused', (tester) async {
    const state = DiscoveryState(
      status: DiscoveryStatus.idle,
      devices: [],
    );

    await tester.pumpWidget(createTestWidget(state));
    await tester.pump();

    expect(find.text('Discovery is paused'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('Renders discovered devices cards and handles tap', (tester) async {
    final device = Device(
      id: 'd-1',
      name: 'MacBook Air M2',
      platform: 'macos',
      ipAddress: '192.168.1.45',
      port: 53317,
      discoveredAt: DateTime.now(),
    );

    final state = DiscoveryState(
      status: DiscoveryStatus.scanning,
      devices: [device],
    );

    Device? selectedDevice;
    await tester.pumpWidget(
      createTestWidget(state, onSelected: (d) => selectedDevice = d),
    );
    await tester.pump();

    expect(find.text('MacBook Air M2'), findsOneWidget);
    expect(find.text('MACOS'), findsOneWidget);
    expect(find.text('192.168.1.45:53317'), findsOneWidget);

    await tester.tap(find.text('MacBook Air M2'));
    await tester.pump();

    expect(selectedDevice, equals(device));
  });
}

class _StaticDiscoveryNotifier extends DiscoveryNotifier {
  _StaticDiscoveryNotifier(DiscoveryState initialState)
      : super(DeviceIdentityService(), _NoOpMdnsService()) {
    state = initialState;
  }
}

class _NoOpMdnsService extends Fake implements MdnsDiscoveryService {
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
