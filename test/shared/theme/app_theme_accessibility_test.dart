import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/shared/theme/app_theme.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme WCAG AA contrast', () {
    const normalTextRatio = 4.5;

    for (final entry in {
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
    }.entries) {
      test('${entry.key} theme meets AA for text on standard surfaces', () {
        final theme = entry.value;
        final scheme = theme.colorScheme;
        final pairs = <String, List<Color>>{
          'onSurface / surface': [scheme.onSurface, scheme.surface],
          'onSurface / scaffold': [
            scheme.onSurface,
            theme.scaffoldBackgroundColor,
          ],
          'onSurfaceVariant / surface': [
            scheme.onSurfaceVariant,
            scheme.surface,
          ],
          'onSurfaceVariant / scaffold': [
            scheme.onSurfaceVariant,
            theme.scaffoldBackgroundColor,
          ],
          'onPrimary / primary': [scheme.onPrimary, scheme.primary],
          'onPrimaryContainer / primaryContainer': [
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ],
          'onSecondary / secondary': [scheme.onSecondary, scheme.secondary],
          'onSecondaryContainer / secondaryContainer': [
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ],
          'onTertiary / tertiary': [scheme.onTertiary, scheme.tertiary],
          'onTertiaryContainer / tertiaryContainer': [
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
          ],
          'onError / error': [scheme.onError, scheme.error],
          'onErrorContainer / errorContainer': [
            scheme.onErrorContainer,
            scheme.errorContainer,
          ],
        };

        for (final pair in pairs.entries) {
          expect(
            _contrastRatio(pair.value[0], pair.value[1]),
            greaterThanOrEqualTo(normalTextRatio),
            reason: '${entry.key} theme fails WCAG AA for ${pair.key}',
          );
        }
      });
    }
  });
}
