import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin seam over local_auth so the app lock can be tested without plugins.
abstract class AppLockGateway {
  Future<bool> isSupported();
  Future<bool> authenticate(String reason);
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}

class LocalAuthAppLockGateway implements AppLockGateway {
  LocalAuthAppLockGateway({
    LocalAuthentication? auth,
    SharedPreferences? prefs,
  })  : _auth = auth ?? LocalAuthentication(),
        _prefs = prefs;

  static const String preferenceKey = 'settings_app_lock_enabled';

  final LocalAuthentication _auth;
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('[AppLock] Device support check failed: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('[AppLock] local_auth unavailable: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      if (!await isSupported()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[AppLock] Authentication failed: $e');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('[AppLock] local_auth unavailable: $e');
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(preferenceKey) ?? false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(preferenceKey, enabled);
  }
}

class AppLockState {
  const AppLockState({
    this.isLoading = true,
    this.isEnabled = false,
    this.isLocked = false,
    this.isBusy = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isEnabled;
  final bool isLocked;
  final bool isBusy;
  final String? errorMessage;

  AppLockState copyWith({
    bool? isLoading,
    bool? isEnabled,
    bool? isLocked,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppLockState(
      isLoading: isLoading ?? this.isLoading,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController(this._gateway) : super(const AppLockState());

  final AppLockGateway _gateway;

  Future<void> initialize({bool lockIfEnabled = true}) async {
    try {
      final enabled = await _gateway.isEnabled();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isEnabled: enabled,
        isLocked: enabled && lockIfEnabled,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load app lock: $e',
      );
    }
  }

  Future<bool> unlock({String reason = 'Unlock NearShare'}) async {
    if (!state.isEnabled || !state.isLocked) return true;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final authenticated = await _gateway.authenticate(reason);
      if (!mounted) return authenticated;
      state = state.copyWith(
        isBusy: false,
        isLocked: authenticated ? false : true,
        errorMessage: authenticated ? null : 'Authentication was not completed.',
        clearError: authenticated,
      );
      return authenticated;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Authentication failed: $e',
      );
      return false;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      if (enabled) {
        final supported = await _gateway.isSupported();
        if (!supported) {
          if (mounted) {
            state = state.copyWith(
              isBusy: false,
              errorMessage: 'This device has no PIN, password, or biometrics.',
            );
          }
          return false;
        }
        final authenticated = await _gateway.authenticate(
          'Confirm it is you to enable app lock',
        );
        if (!authenticated) {
          if (mounted) {
            state = state.copyWith(
              isBusy: false,
              errorMessage: 'Authentication was not completed.',
            );
          }
          return false;
        }
      }

      await _gateway.setEnabled(enabled);
      if (!mounted) return true;
      state = state.copyWith(
        isBusy: false,
        isEnabled: enabled,
        isLocked: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: 'Could not update app lock: $e',
        );
      }
      return false;
    }
  }

  void lock() {
    if (!state.isEnabled) return;
    state = state.copyWith(isLocked: true, clearError: true);
  }
}

final appLockGatewayProvider = Provider<AppLockGateway>((ref) {
  return LocalAuthAppLockGateway();
});

final appLockProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  final controller = AppLockController(ref.watch(appLockGatewayProvider));
  unawaited(controller.initialize());
  return controller;
});
