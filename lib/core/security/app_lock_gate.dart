import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_lock.dart';

/// Covers the app with an authentication prompt whenever the lock is active.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _promptedAfterLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptIfLocked();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      ref.read(appLockProvider.notifier).lock();
      _promptedAfterLaunch = false;
    }
  }

  Future<void> _promptIfLocked() async {
    if (!mounted) return;
    final lockState = ref.read(appLockProvider);
    if (!lockState.isEnabled || !lockState.isLocked) return;
    if (_promptedAfterLaunch) return;
    _promptedAfterLaunch = true;
    await ref.read(appLockProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    if (lock.isLoading) {
      return const ColoredBox(
        color: Color(0xFF0B1220),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (lock.isEnabled && lock.isLocked) {
      return _LockScreen(
        isBusy: lock.isBusy,
        errorMessage: lock.errorMessage,
        onUnlock: () => ref.read(appLockProvider.notifier).unlock(
              reason: AppLocalizations.of(context).unlockNearShare,
            ),
      );
    }
    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.isBusy,
    required this.errorMessage,
    required this.onUnlock,
  });

  final bool isBusy;
  final String? errorMessage;
  final Future<bool> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appLockTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appLockSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: isBusy ? null : () => unawaited(onUnlock()),
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(l10n.unlock),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
