# Phase 0: Project Scaffolding

This document outlines the Phase 0 development plan for the NearShare Flutter app. Phase 0 is strictly focused on project setup, scaffolding, and foundational configuration. No product features are implemented in this phase.

## 0.1 Prerequisites Checklist

Ensure the following tools and SDKs are installed on your development machine before starting:

- **Flutter SDK**: Latest stable version (e.g., 3.x+).
- **Android Studio & Android SDK**: Required for Android development. Ensure the Android toolchain is configured.
- **Xcode** (macOS only): Required for iOS and macOS development.
- **Visual Studio** (Windows only): Required for Windows desktop development (Desktop development with C++ workload).
- **Git**: Version control.

**Verification Commands:**
```bash
# Verify Flutter SDK and required platforms
flutter doctor -v

# Verify Git
git --version
```

## 0.2 Create Flutter Project

Create the Flutter project with the correct organization name and platform support.

**Steps:**
1. Navigate to the root directory where the project will be created (e.g., `d:\canva\`).
2. Run the following command:
```bash
flutter create --org com.nearshare.app --platforms android,ios,windows,macos NearShare
```
3. Navigate into the project directory:
```bash
cd NearShare
```
4. Verify the app runs on your current platform:
```bash
flutter run
```

## 0.3 Folder Structure Setup

Set up a clean architecture-based folder structure inside the `lib/` and `test/` directories.

**Run the following commands to create the structure:**

```bash
# Core folders
mkdir -p lib/core/constants lib/core/errors lib/core/utils lib/core/extensions

# Feature folders (data, domain, presentation for each)
mkdir -p lib/features/discovery/{data,domain,presentation}
mkdir -p lib/features/transfer/{data,domain,presentation}
mkdir -p lib/features/history/{data,domain,presentation}
mkdir -p lib/features/onboarding/{data,domain,presentation}
mkdir -p lib/features/settings/{data,domain,presentation}
mkdir -p lib/features/rooms/{data,domain,presentation}
mkdir -p lib/features/merge_space/{data,domain,presentation}

# Shared folders
mkdir -p lib/shared/widgets lib/shared/theme lib/shared/navigation

# Test folders to match
mkdir -p test/core test/features test/shared
```

## 0.4 Dependencies (pubspec.yaml)

Add all required foundational libraries to `pubspec.yaml`.

**Add the following packages:**

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management & Routing
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0

  # Database
  drift: ^2.16.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  path: ^1.9.0

  # Networking (HTTP / P2P)
  shelf: ^1.4.1
  shelf_io: ^1.0.4
  shelf_router: ^1.1.4
  dio: ^5.4.3.1

  # Discovery
  bonsoir_flutter: ^3.0.0

  # Utilities
  file_picker: ^8.0.0
  permission_handler: ^11.3.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^4.0.1
  uuid: ^4.3.3
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  drift_dev: ^2.16.0
  freezed: ^2.5.2
  json_serializable: ^8.1.0
  mockito: ^5.4.4
```
*Note: Run `flutter pub get` after updating.*

## 0.5 Linting & Analysis

Configure strict linting rules to maintain code quality from day 1.

**Update `analysis_options.yaml`:**
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_declare_return_types
    - cancel_subscriptions
    - close_sinks
    - prefer_single_quotes
    - sort_child_properties_last
    - unawaited_futures
    - require_trailing_commas
```

## 0.6 App Shell

Create the foundational app shell including routing, theming, and state management wrappers.

**1. `lib/shared/theme/app_theme.dart`**
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
```

**2. `lib/features/home/presentation/home_screen.dart`** (Create this folder/file)
```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NearShare')),
      body: const Center(
        child: Text('NearShare App Shell'),
      ),
    );
  }
}
```

**3. `lib/shared/navigation/app_router.dart`**
```dart
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```

**4. `lib/app.dart`**
```dart
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
```

**5. Update `lib/main.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: NearShareApp()));
}
```

## 0.7 CI Pipeline

Set up a basic CI pipeline to ensure code quality on every push/PR.

**Create `.github/workflows/ci.yml`:**
```yaml
name: NearShare CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run code generation
        run: dart run build_runner build -d

      - name: Analyze code
        run: flutter analyze

      - name: Run tests
        run: flutter test

      - name: Build APK (Debug)
        run: flutter build apk --debug
```

*(Note: Add separate macOS runner jobs for iOS/macOS builds if needed, keeping them simple for now.)*

## 0.8 Git Setup

Initialize the repository and configure `.gitignore`.

**Commands:**
```bash
git init
```

The `flutter create` command automatically creates a good `.gitignore`. Ensure you commit the generated structure.

**Initial Commit:**
```bash
git add .
git commit -m "chore: initial project setup and scaffolding"
```

## Tests for Phase 0

Verify the setup by running the following checks locally:

1. **Analysis passes:**
   ```bash
   flutter analyze
   ```
   *(Must return "No issues found!")*

2. **Run tests:**
   Write a simple placeholder test in `test/widget_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:nearshare/app.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';

   void main() {
     testWidgets('HomeScreen renders', (WidgetTester tester) async {
       await tester.pumpWidget(const ProviderScope(child: NearShareApp()));
       expect(find.text('NearShare'), findsWidgets);
     });
   }
   ```
   ```bash
   flutter test
   ```

3. **Build targets successfully:**
   ```bash
   flutter build apk --debug
   # macOS only:
   flutter build ios --no-codesign
   flutter build macos
   # Windows only:
   flutter build windows
   ```

## Acceptance Criteria

Ensure all of the following checkboxes are met before considering Phase 0 complete:

- [ ] Flutter project created and compiles on all target platforms
- [ ] Full folder structure exists
- [ ] All dependencies added and `flutter pub get` succeeds
- [ ] Linting configured and `flutter analyze` passes
- [ ] App shell with theme and router works
- [ ] CI pipeline runs on push
- [ ] At least 1 widget test passes
- [ ] Code committed with tag `phase-0-complete`
