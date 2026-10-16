import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/application/settings_provider.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';

class NearShareApp extends ConsumerWidget {
  const NearShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'NearShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
