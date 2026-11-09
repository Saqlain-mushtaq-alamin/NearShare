import 'package:flutter/widgets.dart';

/// The spacing rhythm used across NearShare.
///
/// Keeping these in one place is what makes screens feel like they were
/// designed together instead of assembled.
abstract final class AppSpacing {
  /// Hairline gaps (icon-to-label, badge padding).
  static const double xs = 4;

  /// Tight coupling (label-to-value, chip internals).
  static const double sm = 8;

  /// Default gap between sibling rows inside a card.
  static const double md = 12;

  /// Screen gutter and standard card padding.
  static const double lg = 16;

  /// Section separation inside a scroll view.
  static const double xl = 24;

  /// Breathing room around hero content and empty states.
  static const double xxl = 32;

  static const EdgeInsets screenPadding = EdgeInsets.all(lg);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius controlRadius = BorderRadius.all(Radius.circular(12));
}
