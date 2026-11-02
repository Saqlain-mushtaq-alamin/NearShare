import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/history_detail_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/merge_space/presentation/merge_conflicts_screen.dart';
import '../../features/merge_space/presentation/merge_devices_screen.dart';
import '../../features/merge_space/presentation/merge_join_screen.dart';
import '../../features/merge_space/presentation/merge_space_screen.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/rooms/presentation/create_room_screen.dart';
import '../../features/rooms/presentation/join_room_screen.dart';
import '../../features/rooms/presentation/room_active_screen.dart';
import '../../features/rooms/presentation/room_transfer_progress_screen.dart';
import '../../features/rooms/presentation/rooms_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transfer/presentation/device_select_screen.dart';
import '../../features/transfer/presentation/file_picker_screen.dart';
import '../../features/transfer/presentation/transfer_complete_screen.dart';
import '../../features/transfer/presentation/transfer_confirmation_screen.dart';
import '../../features/transfer/presentation/transfer_progress_screen.dart';
import '../../shared/widgets/app_logo.dart';
import 'app_shell.dart';

/// Single source of navigation truth. Watches onboarding so a fresh install
/// lands on the welcome flow and a returning user skips it entirely.
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboarding = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (onboarding.isLoading) return null;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarding.isComplete && !onOnboarding) return '/onboarding';
      if (onboarding.isComplete && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadePage(
          const OnboardingScreen(),
          state,
          maintainState: false,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => onboarding.isLoading
                    ? const _BootSplash()
                    : const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'send',
                    pageBuilder: (context, state) =>
                        _slidePage(const FilePickerScreen(), state),
                    routes: [
                      GoRoute(
                        path: 'select-device',
                        pageBuilder: (context, state) =>
                            _slidePage(const DeviceSelectScreen(), state),
                      ),
                      GoRoute(
                        path: 'confirm',
                        pageBuilder: (context, state) => _slidePage(
                          const TransferConfirmationScreen(),
                          state,
                        ),
                      ),
                      GoRoute(
                        path: 'progress/:transferId',
                        pageBuilder: (context, state) {
                          final transferId =
                              state.pathParameters['transferId'] ?? 'active';
                          return _slidePage(
                            TransferProgressScreen(transferId: transferId),
                            state,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'complete/:transferId',
                        pageBuilder: (context, state) {
                          final transferId =
                              state.pathParameters['transferId'] ?? '';
                          return _slidePage(
                            TransferCompleteScreen(transferId: transferId),
                            state,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':transferId',
                    pageBuilder: (context, state) {
                      final transferId =
                          state.pathParameters['transferId'] ?? '';
                      return _slidePage(
                        HistoryDetailScreen(transferId: transferId),
                        state,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rooms',
                builder: (context, state) => const RoomsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (context, state) =>
                        _slidePage(const CreateRoomScreen(), state),
                  ),
                  GoRoute(
                    path: 'join',
                    pageBuilder: (context, state) =>
                        _slidePage(const JoinRoomScreen(), state),
                  ),
                  GoRoute(
                    path: 'active/:roomId',
                    pageBuilder: (context, state) {
                      final roomId = state.pathParameters['roomId'] ?? '';
                      return _slidePage(
                        RoomActiveScreen(roomId: roomId),
                        state,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'transfer',
                        pageBuilder: (context, state) {
                          final roomId = state.pathParameters['roomId'] ?? '';
                          return _slidePage(
                            RoomTransferProgressScreen(roomId: roomId),
                            state,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/merge-space',
                builder: (context, state) => const MergeSpaceScreen(),
                routes: [
                  GoRoute(
                    path: 'setup',
                    pageBuilder: (context, state) =>
                        _slidePage(const MergeSpaceScreen(), state),
                  ),
                  GoRoute(
                    path: 'join',
                    pageBuilder: (context, state) =>
                        _slidePage(const MergeJoinScreen(), state),
                  ),
                  GoRoute(
                    path: 'devices',
                    pageBuilder: (context, state) =>
                        _slidePage(const MergeDevicesScreen(), state),
                  ),
                  GoRoute(
                    path: 'conflicts',
                    pageBuilder: (context, state) =>
                        _slidePage(const MergeConflictsScreen(), state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Soft push transition: fade + a few pixels of upward drift.
CustomTransitionPage<T> _slidePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<T> _fadePage<T>(
  Widget child,
  GoRouterState state, {
  bool maintainState = true,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    maintainState: maintainState,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Shown for the few milliseconds while prefs load, so first launch never
/// flashes the home screen before onboarding redirects.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(
              size: 72,
              padding: 14,
              background: Color(0xFF1A4BCF),
            ),
            const SizedBox(height: 16),
            Text(
              'NearShare',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
