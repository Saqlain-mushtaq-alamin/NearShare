import 'package:flutter/material.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';

class NearShareApp extends StatelessWidget {
  const NearShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NearShare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
