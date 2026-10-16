import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../discovery/data/device_identity_service.dart';
import '../../discovery/presentation/discovery_provider.dart';

/// Prefs keys owned by onboarding (exported so tests can seed them).
abstract final class OnboardingKeys {
  static const String complete = 'nearshare_onboarding_complete';
}

@immutable
class OnboardingState {
  const OnboardingState({
    this.isLoading = true,
    this.isComplete = false,
    this.deviceName,
  });

  final bool isLoading;

  /// True once the user has finished (or previously finished) onboarding.
  final bool isComplete;

  /// Suggested / chosen device name, ready to drop into the name field.
  final String? deviceName;

  OnboardingState copyWith({
    bool? isLoading,
    bool? isComplete,
    String? deviceName,
    bool clearDeviceName = false,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      deviceName:
          clearDeviceName ? null : (deviceName ?? this.deviceName),
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    SharedPreferences? prefs,
    required DeviceIdentityService identity,
  })  : _prefs = prefs,
        _identity = identity,
        super(const OnboardingState());

  final SharedPreferences? _prefs;
  final DeviceIdentityService _identity;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Reads the completion flag and the suggested device name. Called once by
  /// the provider on first read.
  Future<void> load() async {
    try {
      final prefs = await _ensurePrefs();
      final complete = prefs.getBool(OnboardingKeys.complete) ?? false;
      String? name;
      try {
        name = await _identity.getOrCreateDeviceName();
      } catch (_) {
        name = null;
      }
      if (!mounted) return;
      state = OnboardingState(
        isLoading: false,
        isComplete: complete,
        deviceName: name,
      );
    } catch (_) {
      // Prefs unavailable (e.g. bare test host) — treat as a fresh install.
      if (!mounted) return;
      state = const OnboardingState(isLoading: false, isComplete: false);
    }
  }

  /// Persists the chosen device name (if any) and flips the completion flag.
  Future<void> completeOnboarding({String? deviceName}) async {
    final trimmed = deviceName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await _identity.setDeviceName(trimmed);
    }
    final prefs = await _ensurePrefs();
    await prefs.setBool(OnboardingKeys.complete, true);
    final resolvedName = await _identity.getOrCreateDeviceName();
    if (!mounted) return;
    state = OnboardingState(
      isLoading: false,
      isComplete: true,
      deviceName: resolvedName,
    );
  }

  /// Clears the flag — used by "replay onboarding" in settings and tests.
  Future<void> reset() async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(OnboardingKeys.complete, false);
    if (!mounted) return;
    state = state.copyWith(isComplete: false);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final identity = ref.watch(deviceIdentityServiceProvider);
  return OnboardingNotifier(identity: identity)..load();
});
