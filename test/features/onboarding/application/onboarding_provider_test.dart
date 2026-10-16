import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/data/device_identity_service.dart';
import 'package:nearshare/features/onboarding/application/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    OnboardingNotifier buildNotifier() {
      return OnboardingNotifier(
        prefs: prefs,
        identity: DeviceIdentityService(prefs: prefs),
      );
    }

    test('starts loading and reports incomplete on a fresh install', () async {
      final notifier = buildNotifier();
      expect(notifier.state.isLoading, isTrue);

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isComplete, isFalse);
    });

    test('completeOnboarding flips the flag and persists it', () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.completeOnboarding();

      expect(notifier.state.isComplete, isTrue);
      expect(prefs.getBool(OnboardingKeys.complete), isTrue);

      // A brand-new notifier (same prefs) sees the completed state.
      final reopened = buildNotifier();
      await reopened.load();
      expect(reopened.state.isComplete, isTrue);
    });

    test('completeOnboarding saves the chosen device name', () async {
      final notifier = buildNotifier();
      await notifier.load();

      await notifier.completeOnboarding(deviceName: '  Rafiul\u2019s Pixel 8  ');

      expect(prefs.getString('nearshare_device_name'), 'Rafiul\u2019s Pixel 8');
      expect(notifier.state.deviceName, 'Rafiul\u2019s Pixel 8');
    });

    test('a blank device name keeps the generated one', () async {
      final notifier = buildNotifier();
      await notifier.load();
      final generated = notifier.state.deviceName;

      await notifier.completeOnboarding(deviceName: '   ');

      expect(notifier.state.deviceName, generated);
    });

    test('reset clears the completion flag', () async {
      final notifier = buildNotifier();
      await notifier.load();
      await notifier.completeOnboarding();

      await notifier.reset();

      expect(notifier.state.isComplete, isFalse);
      expect(prefs.getBool(OnboardingKeys.complete), isFalse);
    });
  });
}
