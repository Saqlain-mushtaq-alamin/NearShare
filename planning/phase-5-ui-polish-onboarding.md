# NearShare Development Plan - Phase 5: UI Polish, Onboarding & Settings

## Goals
Transform the NearShare app from a functional prototype into a polished, user-friendly product. The focus is on a clean, fast, and trustworthy UI (Material 3), a seamless first-time onboarding experience, comprehensive platform-specific permissions handling, and a fully functional settings screen.

## Prerequisites
- Phases 1-4 (Discovery, Transfer, Resume, History) are fully implemented and tested.
- State management relies on Riverpod.
- Routing is handled by GoRouter.
- Required packages: `permission_handler`, `flutter_native_splash`, `shared_preferences`, `google_fonts` (optional), `device_info_plus`.

---

## Detailed Implementation Steps

### 5.1 App Theme & Design System
Centralize all styling to ensure a consistent, non-bloated aesthetic.

**Directory:** `lib/shared/theme/`

- **`app_theme.dart`**: Implement Material 3 themes.
  - *Light Theme*: Deep blue primary, white surface, teal accent.
  - *Dark Theme*: Light blue primary, near-black surface.
  - Provide a custom `ThemeExtension` for transfer-specific colors (e.g., success green, error red, progress blue).
- **`app_text_styles.dart`**: Define standard `TextStyle` constants mapping to Material typography (display, headline, title, body, label).
- **`app_spacing.dart`**: Standardize padding/margins (`8.0`, `12.0`, `16.0`, `24.0`, `32.0`).
- **`app_icons.dart`**: Centralize `IconData` or SVG asset paths mapping file types, platforms, and actions.

### 5.2 Onboarding Flow (First Launch Only)
A fast (<10s) introductory flow.

**Directory:** `lib/features/onboarding/presentation/` & `application/`

- **`onboarding_screen.dart`**: A `PageView` with 3 steps:
  1. **Welcome**: Logo + Tagline ("Send files. No internet. No account. No ads.") + "Get Started" button.
  2. **Permissions**: Request required permissions based on the platform, with short 1-line explanations for each.
  3. **Device Name**: Pre-filled text field (via `device_info_plus` like "Rafiul's Pixel 8"). User can edit. "Done" button.
- **`onboarding_provider.dart`**: Manages the onboarding state using `SharedPreferences`. Exposes a boolean `isOnboardingComplete`.

### 5.3 Permissions Handling
Abstract platform-specific permissions.

**Directory:** `lib/core/utils/`

- **`permission_service.dart`**:
  - Encapsulates `permission_handler` logic.
  - Identifies platform requirements (Android: Nearby Devices, Storage, Wi-Fi states; iOS: Local Network, Photos).
  - Handles "permanently denied" states by showing a dialog pointing to OS settings.
  - Supports graceful degradation if non-critical permissions are denied.

### 5.4 Home Screen Redesign
The central hub of the app.

**Directory:** `lib/features/home/presentation/`

- **`home_screen.dart`**:
  - **Top**: Prominent primary-colored "Send" button. Below it, a pulsing "Ready to receive" indicator.
  - **Middle**: "Nearby Devices" list that auto-refreshes based on mDNS/discovery.
  - **Bottom**: "Recent Transfers" list (3-5 items) with a "See All" button.
  - **Banner**: Conditionally displayed if paused/incomplete transfers exist ("1 transfer paused — Tap to resume").
  - **FAB**: Floating "Send" action for quick access.

### 5.5 Send Flow UI Polish
Revamp the steps to send a file.

**Directory:** `lib/features/transfer/presentation/` (or similar)

- **`file_picker_screen.dart`**:
  - Tabbed interface (Photos | Videos | Documents | Apps | All Files).
  - Grid view for visual media, List view for documents with icons.
  - Bottom bar with selected file count, total size, and a "Next" button.
- **`device_select_screen.dart`**:
  - Display discovered devices as cards with platform-specific icons (Android, Apple, Windows).
  - Add "Last used" tags. Include scanning radar animations.
- **`transfer_progress_screen.dart`**:
  - Large circular progress indicator showing percentage.
  - Text for current file, speed (e.g., "12.5 MB/s"), and ETA.
  - "Cancel" button triggering a confirmation dialog.
- **`transfer_complete_screen.dart`**:
  - Success/Failure hero animation (checkmark/X).
  - Summary text (e.g., "3 files sent to Rafiul's Pixel").
  - "Send More" and "Done" navigation buttons.

### 5.6 Receive Flow UI Polish
Make receiving frictionless.

**Directory:** `lib/features/transfer/presentation/`

- **`incoming_transfer_sheet.dart`**: A sliding bottom sheet.
  - Shows sender name, device icon, file preview list, and total size.
  - Primary "Accept" and secondary "Decline" buttons.
  - Auto-dismisses (rejects) after 60 seconds if untouched.

### 5.7 Settings Screen
Configuration and app info.

**Directory:** `lib/features/settings/presentation/` & `application/`

- **`settings_screen.dart`**:
  - **Device**: Edit Device Name, copy Device ID.
  - **Storage**: View/Change save location, show NearShare storage usage.
  - **Transfer**: Auto-accept toggle for known devices, transfer encryption toggle.
  - **App**: Theme selection (System/Light/Dark), Language (prepared for l10n).
  - **Data**: Clear transfer history, Clear cache.
  - **About**: Version info, Privacy stance ("We don't collect your data. Full stop."), Open source licenses, Rate app link.
- **`settings_provider.dart`**: Interfaces with `SharedPreferences` to load and save the above preferences reactively.

### 5.8 Navigation & Bottom Nav Bar
Update GoRouter to use a `StatefulShellRoute` for bottom navigation.

**Directory:** `lib/core/routing/`

- **`app_router.dart`**:
  - Redirect logic: If `!isOnboardingComplete`, redirect to `/onboarding`.
  - Main Tabs: Home (House), History (Clock), Rooms (People - "Coming Soon"), Settings (Gear).

### 5.9 Empty States & Error States
Provide helpful context when there is no data or an error occurs.

- **Empty States**:
  - Nearby devices: "Make sure both devices are on the same Wi-Fi."
  - History: "Your transfer history will appear here."
  - File Picker: "Select files to send."
- **Error States**: Network errors, permission denied screens, transfer failed with details and a retry button.

### 5.10 Animations & Micro-interactions
- Use Flutter's built-in `Hero`, `AnimatedSwitcher`, and `PageRouteBuilder` for seamless screen transitions (fade/slide).
- Add pulse animations for device discovery.
- Use `AnimatedContainer` or `TweenAnimationBuilder` for smooth progress bars.
- Add `InkWell` ripple effects to interactive elements.

### 5.11 App Icon & Splash Screen
- **Icon**: Two overlapping arrows or a clean share symbol.
- **Splash**: Configure `flutter_native_splash.yaml` to show the app logo with matching background colors for light/dark modes.

---

## Tests

### Unit Tests (minimum 8)
1. `PermissionService`: Validates correct permissions are requested per platform mapping.
2. `OnboardingProvider`: Tracks completion state correctly.
3. `SettingsProvider`: Saves and loads all settings successfully.
4. `SettingsProvider`: Validates theme mode changes propagate to the state.
5. `Device Name Generation`: Ensures fallback logic uses `device_info_plus` correctly.
6. `GoRouter`: Redirects to onboarding when not completed.
7. `GoRouter`: Bypasses onboarding when already completed.
8. `File Categorization`: Correctly assigns files to tabs based on mime types.

### Widget Tests (minimum 10)
1. `OnboardingScreen`: Verifies the 3 pages render and pagination works.
2. `OnboardingScreen` (Permissions): Shows correct required permissions per mocked platform.
3. `OnboardingScreen` (Device Name): Displays auto-generated name correctly in the text field.
4. `HomeScreen`: Renders the Send button, receive indicator, device list, and recent transfers.
5. `HomeScreen`: Shows incomplete transfer banner when state indicates a paused transfer.
6. `SettingsScreen`: Verifies all settings sections render correctly.
7. `SettingsScreen`: Theme toggle switch changes state appropriately.
8. `SettingsScreen`: "Clear history" triggers the confirmation dialog.
9. `BottomNavigationBar`: Verifies 4 tabs render and tapping them changes the shell route.
10. `Empty States`: Verifies appropriate placeholder text/images are shown when lists are empty.

### Visual / Manual Tests
1. Complete onboarding flow on Android and iOS physical devices.
2. Verify dark mode looks correct on all screens.
3. Verify all screens handle landscape orientation gracefully.
4. Verify accessibility: text scales properly with system font size changes.
5. Execute a full send/receive flow observing the polished UI elements.
6. Verify settings persist after force-closing and restarting the app.

---

## Acceptance Criteria
- [ ] Material 3 theme implemented with cohesive light and dark modes.
- [ ] Onboarding flow works on first launch (completion time <10 seconds).
- [ ] Permissions properly requested, handled, and gracefully degraded per OS.
- [ ] Home screen redesigned featuring large Send button, device list, and recent transfers.
- [ ] Send flow polished (tabbed file picker, clear device cards, engaging progress UI).
- [ ] Receive flow utilizes an auto-dismissing bottom sheet with file previews.
- [ ] Settings screen fully functional and persists choices.
- [ ] App uses a Bottom Navigation Bar with 4 distinct tabs via GoRouter.
- [ ] Empty states and error states defined and visible for all relevant screens.
- [ ] Smooth animations and transitions implemented throughout.
- [ ] App icon and native splash screen configured.
- [ ] Minimum 8 Unit Tests implemented and passing.
- [ ] Minimum 10 Widget Tests implemented and passing.
- [ ] `flutter analyze` passes with zero warnings.
- [ ] Code committed with tag `phase-5-complete`.
