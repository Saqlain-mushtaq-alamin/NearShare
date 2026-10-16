import 'package:go_router/go_router.dart';

import '../../features/history/presentation/history_detail_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rooms/presentation/rooms_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transfer/presentation/device_select_screen.dart';
import '../../features/transfer/presentation/file_picker_screen.dart';
import '../../features/transfer/presentation/transfer_complete_screen.dart';
import '../../features/transfer/presentation/transfer_confirmation_screen.dart';
import '../../features/transfer/presentation/transfer_progress_screen.dart';
import 'app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'send',
                  builder: (context, state) => const FilePickerScreen(),
                  routes: [
                    GoRoute(
                      path: 'select-device',
                      builder: (context, state) => const DeviceSelectScreen(),
                    ),
                    GoRoute(
                      path: 'confirm',
                      builder: (context, state) =>
                          const TransferConfirmationScreen(),
                    ),
                    GoRoute(
                      path: 'progress/:transferId',
                      builder: (context, state) {
                        final transferId =
                            state.pathParameters['transferId'] ?? 'active';
                        return TransferProgressScreen(transferId: transferId);
                      },
                    ),
                    GoRoute(
                      path: 'complete/:transferId',
                      builder: (context, state) {
                        final transferId =
                            state.pathParameters['transferId'] ?? '';
                        return TransferCompleteScreen(transferId: transferId);
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
                  builder: (context, state) {
                    final transferId = state.pathParameters['transferId'] ?? '';
                    return HistoryDetailScreen(transferId: transferId);
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
