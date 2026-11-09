import 'package:flutter/material.dart';

/// Text styles shared between screens.
///
/// Everything derives from the active [ThemeData] so light/dark and system
/// text-scaling keep working for free.
abstract final class AppTextStyles {
  /// Uppercase eyebrow above a settings or list section ("DEVICE", "DATA").
  static TextStyle sectionLabel(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ) ??
        const TextStyle();
  }

  /// Primary line of a card or list tile.
  static TextStyle cardTitle(ThemeData theme) {
    return theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle();
  }

  /// Supporting copy under a card title.
  static TextStyle cardSubtitle(ThemeData theme) {
    return theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        const TextStyle();
  }

  /// Emphasized value (file size, speed, percentage).
  static TextStyle value(ThemeData theme) {
    return theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle();
  }

  /// Helper text in empty states and onboarding captions.
  static TextStyle muted(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        const TextStyle();
  }
}
