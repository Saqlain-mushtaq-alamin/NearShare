import 'package:flutter/material.dart';

/// Transfer-specific colours layered on top of Material 3.
///
/// Success/error/progress get their own extension so every transfer screen
/// reads the same green tick and the same red failure, light or dark.
@immutable
class TransferPalette extends ThemeExtension<TransferPalette> {
  const TransferPalette({
    required this.success,
    required this.error,
    required this.progress,
    required this.warning,
  });

  final Color success;
  final Color error;
  final Color progress;
  final Color warning;

  static const TransferPalette light = TransferPalette(
    success: Color(0xFF137A43),
    error: Color(0xFFC62828),
    progress: Color(0xFF1A4BCF),
    warning: Color(0xFFB26A00),
  );

  static const TransferPalette dark = TransferPalette(
    success: Color(0xFF5DD99A),
    error: Color(0xFFFF8A80),
    progress: Color(0xFF8FB4FF),
    warning: Color(0xFFFFC46B),
  );

  @override
  TransferPalette copyWith({
    Color? success,
    Color? error,
    Color? progress,
    Color? warning,
  }) {
    return TransferPalette(
      success: success ?? this.success,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      warning: warning ?? this.warning,
    );
  }

  @override
  TransferPalette lerp(TransferPalette? other, double t) {
    if (other is! TransferPalette) return this;
    return TransferPalette(
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  /// Deep blue — the brand colour.
  static const Color deepBlue = Color(0xFF1A4BCF);

  /// Teal used for secondary accents and the receive side of the UI.
  static const Color teal = Color(0xFF00988B);

  /// Near-black surface for dark mode.
  static const Color darkSurface = Color(0xFF11151B);

  static ThemeData get lightTheme => _base(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: deepBlue,
          brightness: Brightness.light,
          secondary: teal,
          surface: Colors.white,
        ),
        palette: TransferPalette.light,
      );

  static ThemeData get darkTheme => _base(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: deepBlue,
          brightness: Brightness.dark,
          secondary: teal,
          surface: darkSurface,
        ),
        palette: TransferPalette.dark,
      );

  /// Convenience accessor for the transfer palette of the current theme.
  static TransferPalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<TransferPalette>() ?? TransferPalette.light;
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme scheme,
    required TransferPalette palette,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: scheme,
    ).englishLike.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? darkSurface : const Color(0xFFF7F8FA),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerHighest.withValues(alpha: 0.35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.5),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHighest.withValues(alpha: 0.3) : scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainerLow : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
