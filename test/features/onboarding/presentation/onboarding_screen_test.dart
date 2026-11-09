import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/providers/app_providers.dart';
import 'package:nearshare/core/utils/permission_service.dart';
import 'package:nearshare/features/discovery/presentation/discovery_provider.dart';
import 'package:nearshare/features/onboarding/application/onboarding_provider.dart';
import 'package:nearshare/features/onboarding/presentation/onboarding_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/presentation_stubs.dart';

class _FakeGateway implements PermissionGateway {
  final List<Permission> requested = [];
  var grantOnRequest = true;

  @override
  Future<PermissionStatus> check(Permission permission) async =>
      requested.contains(permission) && grantOnRequest
          ? PermissionStatus.granted
          : PermissionStatus.denied;

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requested.add(permission);
    return grantOnRequest ? PermissionStatus.granted : PermissionStatus.denied;
  }

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpOnboarding(
    WidgetTester tester, {
    AppPlatform platform = AppPlatform.android,
  }) async {
    final gateway = _FakeGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(
            PermissionService(gateway: gateway, platform: platform),
          ),
          deviceIdentityServiceProvider
              .overrideWithValue(FakeDeviceIdentityService()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('renders the welcome page and walks through all three steps',
        (tester) async {
      await pumpOnboarding(tester);

      expect(find.text('NearShare'), findsOneWidget);
      expect(
        find.text('Send files. No internet.\nNo account. No ads.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('onboarding-get-started')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-skip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      expect(find.text('A couple of things first'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();

      expect(
        find.text('What should others call this device?'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('onboarding-done')), findsOneWidget);
    });

    testWidgets('shows the permissions required by the mocked platform',
        (tester) async {
      await pumpOnboarding(tester, platform: AppPlatform.android);
      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      expect(find.text('Nearby devices'), findsOneWidget);
      expect(find.text('Photos and videos'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.byKey(const Key('onboarding-allow-access')), findsOneWidget);
    });

    testWidgets('iOS onboarding lists local network instead of nearby devices',
        (tester) async {
      await pumpOnboarding(tester, platform: AppPlatform.ios);
      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();

      expect(find.text('Local network'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Nearby devices'), findsNothing);
    });

    testWidgets('device name field is pre-filled with the generated name',
        (tester) async {
      final container = await pumpOnboarding(tester);
      final suggested =
          container.read(onboardingProvider).deviceName ?? 'NearShare Peer';

      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('onboarding-name-field')),
      );
      expect(field.controller!.text, suggested);
    });

    testWidgets('Done completes onboarding with the edited name',
        (tester) async {
      final container = await pumpOnboarding(tester);

      await tester.tap(find.byKey(const Key('onboarding-get-started')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-continue')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('onboarding-name-field')),
        'Kitchen iPad',
      );
      await tester.tap(find.byKey(const Key('onboarding-done')));
      await tester.pumpAndSettle();

      final state = container.read(onboardingProvider);
      expect(state.isComplete, isTrue);
      expect(state.deviceName, 'Kitchen iPad');
    });

    testWidgets('Skip finishes onboarding from any step', (tester) async {
      final container = await pumpOnboarding(tester);

      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();

      expect(container.read(onboardingProvider).isComplete, isTrue);
    });
  });
}
