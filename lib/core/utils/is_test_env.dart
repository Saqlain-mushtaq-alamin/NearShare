import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True when the app is running inside `flutter test`.
///
/// The test tool sets the FLUTTER_TEST environment variable (it is not a
/// dart-define), so `bool.fromEnvironment` cannot see it. Infinite decorative
/// animations are suppressed under test so `pumpAndSettle` can finish.
bool get isRunningUnderTest =>
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
