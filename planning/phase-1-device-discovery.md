# NearShare Phase 1: Device Discovery (mDNS)

This document outlines the first phase of developing the NearShare Flutter app: implementing local network device discovery using mDNS/Bonjour.

## 1. Context & Goals

- **Framework**: Flutter with Riverpod for state management.
- **Discovery Mechanism**: mDNS (Multicast DNS) service registration and discovery via the `bonsoir_flutter` package.
- **Platforms Supported**: Android and iOS.
- **Objective**: Discover nearby devices running NearShare on the same Wi-Fi network without relying on a backend server.

---

## 2. Implementation Steps

### 1.1 How mDNS Discovery Works

**mDNS (Multicast DNS)** allows resolving hostnames to IP addresses within small networks that do not include a local name server. It is primarily used for zero-configuration networking.
- **Bonjour/NSD**: Apple's implementation is called Bonjour, while Android uses Network Service Discovery (NSD). Both utilize mDNS and DNS-SD (DNS Service Discovery).
- **Service Naming**: NearShare will broadcast its presence using the service type `_nearshare._tcp`.
- **Broadcast Information**: The broadcast will advertise a custom TXT record containing:
  - Device Name (user-editable)
  - Port (for future file transfers)
  - Device ID (a unique UUID)
  - Platform (Android/iOS)

### 1.2 Domain Models

Create the core domain models.

**File: `lib/features/discovery/domain/device.dart`**
```dart
class Device {
  final String id;          // UUID, generated on first launch, persisted
  final String name;        // User-editable device name
  final String platform;    // android, ios, windows, macos
  final String ipAddress;
  final int port;
  final DateTime discoveredAt;

  Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.ipAddress,
    required this.port,
    required this.discoveredAt,
  });

  // Add copyWith, == operator, and hashCode
}
```

**File: `lib/features/discovery/domain/discovery_state.dart`**
```dart
enum DiscoveryStatus { idle, scanning, error }

class DiscoveryState {
  final DiscoveryStatus status;
  final List<Device> devices;
  final String? errorMessage;

  DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.devices = const [],
    this.errorMessage,
  });
  
  // Add copyWith
}
```

### 1.3 Data Layer

**File: `lib/features/discovery/data/device_identity_service.dart`**
Generates and persists (via `SharedPreferences`) the local device's UUID and name on the first launch. Provides current device identity information.

**File: `lib/features/discovery/data/mdns_discovery_service.dart`**
A wrapper around `bonsoir_flutter`:
- `startBroadcast()`: Registers the `_nearshare._tcp` service with TXT records (id, name, platform).
- `startDiscovery()`: Listens for other `_nearshare._tcp` services.
- `stopBroadcast()` / `stopDiscovery()`: Cleanly shuts down services.
- Listens to service resolved events to construct `Device` models.
- Listens to service lost events to remove devices that go offline.

### 1.4 Presentation Layer (Riverpod Providers)

**File: `lib/features/discovery/presentation/discovery_provider.dart`**
A `StateNotifierProvider` or `NotifierProvider` that manages the `DiscoveryState`:
- Auto-starts broadcasting and discovery when the application is in the foreground.
- Stops operations when transitioning to the background.
- Maintains the list of currently visible devices.

**File: `lib/features/discovery/presentation/device_list_widget.dart`**
A widget to display discovered devices:
- Shows device name, platform icon, and a subtle IP address.
- Displays an empty state ("No devices found").
- Shows a scanning indicator when `status == DiscoveryStatus.scanning`.

**Update `HomeScreen`**: Integrate `DeviceListWidget` into the main application screen.

### 1.5 Platform-Specific Setup

#### **Android**
Modify `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions for mDNS and network access -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>

    <!-- For Android 12+ NSD Queries -->
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
        </intent>
    </queries>
    
    <application ...>
        <!-- ... -->
    </application>
</manifest>
```

#### **iOS**
Modify `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- ... -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>NearShare needs local network access to discover nearby devices for file transfer.</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_nearshare._tcp</string>
    </array>
    <!-- ... -->
</dict>
```

### 1.6 Lifecycle Management
Use `AppLifecycleListener` or `WidgetsBindingObserver` within your initialization logic or Riverpod providers to listen to app state changes.
- Start broadcast & discovery on `AppLifecycleState.resumed`.
- Stop broadcast & discovery on `AppLifecycleState.paused` to conserve battery.

---

## 5. Tests

### Unit Tests (`test/`)
1. **Device Model**: Verify creation, equality (`==`), and JSON serialization/deserialization.
2. **DeviceIdentityService**: Check that a UUID is generated on the first call and subsequently retrieved from `SharedPreferences` (using mocks).
3. **DiscoveryState**: Verify state transitions (idle → scanning → devices found / error).
4. **Discovery Provider**: Mock `MdnsDiscoveryService` to verify:
   - Starts in `idle` state.
   - Transitions to `scanning` when started.
   - Properly adds devices when services resolve.
   - Properly removes devices when services are lost.
   - Returns to `idle` when stopped.

### Widget Tests (`test/`)
1. **DeviceListWidget Empty State**: Ensure the correct message is shown when the device list is empty.
2. **DeviceListWidget Populated**: Render device cards when devices are present.
3. **DeviceListWidget Scanning**: Display the scanning indicator when the state status is `scanning`.
4. **HomeScreen Integration**: Ensure the `DeviceListWidget` is correctly integrated and displayed.

### Integration Tests (Manual - 2 Physical Devices)
1. Install the app on two distinct devices on the same Wi-Fi network.
2. Verify both devices discover each other within 5 seconds.
3. Turn off Wi-Fi on Device A; verify it disappears from Device B's list.
4. Turn Wi-Fi back on Device A; verify it reappears on Device B's list.

---

## 6. Acceptance Criteria

- [ ] `bonsoir_flutter` is integrated and configured.
- [ ] Device model and identity service are implemented.
- [ ] mDNS broadcast registers the device on the local network.
- [ ] mDNS discovery finds other NearShare devices.
- [ ] Devices dynamically appear/disappear in real-time as they connect/disconnect.
- [ ] Android permissions are correctly configured and requested.
- [ ] iOS `Info.plist` is configured for local network and Bonjour.
- [ ] Application lifecycle effectively manages starting and stopping discovery.
- [ ] All Unit tests pass (minimum 8 tests).
- [ ] All Widget tests pass (minimum 4 tests).
- [ ] Manual 2-device integration test is fully successful.
- [ ] `flutter analyze` passes with zero issues.
- [ ] Code is committed and tagged with `phase-1-complete`.
