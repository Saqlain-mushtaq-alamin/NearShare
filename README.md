# NearShare

**Your files never leave your Wi-Fi. No account. No ads. No cloud.**

NearShare is a cross-platform Flutter app for direct device-to-device file
transfer, group rooms, and folder synchronization over the local network. It
uses mDNS for discovery and an HTTP-based peer protocol for transport. Nothing
is uploaded to a third-party service.

## Features

- **Nearby transfer** — discover devices on the same LAN and send files or
  folders with progress, cancellation, and resumable chunks.
- **Rooms** — let multiple people join a host session, share files, and see
  room activity.
- **Merge Space** — pair devices and keep shared folders synchronized with
  conflict detection and encrypted peer records.
- **Transfer history** — review completed, failed, and cancelled transfers.
- **Privacy first** — optional app lock, encrypted local databases, pinned TLS
  for device transfer, and no telemetry or analytics.

## Requirements

- Flutter `3.32.x` with Dart `3.8.x`
- Android SDK for Android builds
- Xcode and CocoaPods for iOS builds
- Windows desktop tooling for Windows builds

## Build and Run

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Build a release APK:

```powershell
flutter build apk --release
```

Build for iOS (macOS required):

```bash
flutter build ios --release
```

Run the checks used by CI:

```powershell
flutter analyze
flutter test
```

## Platform Notes

- Android requires local network and Wi-Fi multicast permissions for mDNS.
  Android app backups are disabled so local secrets are not copied off-device.
- iOS requires the local network usage description and Face ID usage
  description already configured in `ios/Runner/Info.plist`.
- Desktop and mobile devices must be on the same LAN. Networks that block
  multicast may require manual IP entry or QR-code pairing.
- HTTP is permitted only as a local-network fallback. Transfer traffic uses
  pinned TLS when both peers advertise certificate fingerprints.

## Project Layout

```text
lib/
  core/                 shared security, errors, providers, utilities
  features/
    discovery/          mDNS and QR-based device discovery
    transfer/           resumable chunk transport and transfer UI
    rooms/              host/member room protocol and UI
    merge_space/        paired-device synchronization
    history/            Drift-backed transfer history
    settings/           user preferences and app lock
    onboarding/         first-run experience
  l10n/                 generated localization classes and ARB sources
  shared/               theme, navigation, reusable widgets
planning/               product specification and phase plans
test/                   unit, widget, and protocol integration tests
```

## Security Summary

- Self-signed per-device TLS certificates with SHA-256 fingerprint pinning.
- SHA-256 checksum verification for received files.
- Local-network-only request filtering, rate limiting, concurrency limits,
  request timeouts, and body-size limits on HTTP servers.
- SQLCipher-encrypted history and Merge Space databases.
- Secrets and TLS private keys stored with `flutter_secure_storage`.
- Optional biometric/PIN app lock backed by `local_auth`.
- Filename sanitization for path traversal, reserved names, long names, and
  Unicode-safe truncation.

See [ARCHITECTURE.md](ARCHITECTURE.md) for protocol details and
[PRIVACY.md](PRIVACY.md) for the privacy policy.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Security
issues should be reported privately where possible rather than disclosed in a
public issue.

## License

MIT. See [LICENSE](LICENSE).
