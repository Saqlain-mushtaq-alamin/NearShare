# Contributing to NearShare

Thanks for helping improve NearShare. The project is local-first and
privacy-focused; contributions must preserve those properties.

## Development Setup

1. Install Flutter `3.32.x` with Dart `3.8.x`.
2. Run `flutter pub get`.
3. Generate Drift, Freezed, JSON, and Riverpod code with:

   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app with `flutter run`.

For platform-specific builds, install the Android SDK, Xcode/CocoaPods, or the
Windows desktop toolchain as needed.

## Before Opening a Pull Request

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Both commands must pass with zero analyzer issues and no failing tests. If your
change affects networking, encryption, file handling, or storage, add or update
tests in the matching directory under `test/`.

## Code Guidelines

- Follow the existing feature layout: `domain/`, `data/`, and
  `presentation/`.
- Keep domain models and rules free of Flutter UI dependencies.
- Use Riverpod providers for shared state and existing service abstractions for
  I/O so tests can substitute fakes.
- Prefer streaming file I/O. Do not load whole files into memory.
- Preserve local-first behavior. Do not add analytics, telemetry, cloud
  relays, crash reporters, or third-party SDKs that transmit user data.
- Never log secrets, private keys, group keys, room codes, or file contents.
- Keep user-visible strings ready for localization. Add new English strings to
  `lib/l10n/app_en.arb` where practical.
- Use `flutter_secure_storage` for secrets and SQLCipher for local databases.
- Add comments only where the reason for a non-obvious decision is not clear
  from the code.

## Security-Sensitive Changes

Changes to discovery, TLS, certificate pinning, authentication, encryption,
rate limiting, local-network checks, or file path handling require extra care.
Include:

- A short explanation of the threat being addressed.
- Tests for accepted and rejected inputs.
- A note about platform differences if behavior varies on Android, iOS,
  Windows, macOS, or Linux.

Please report vulnerabilities privately to the maintainers rather than opening
a public issue with exploit details. If no private channel is available, open a
minimal issue asking for a private contact method.

## Pull Request Checklist

- [ ] The change is focused and described clearly.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] New behavior has tests.
- [ ] No secrets, generated build artifacts, or unrelated files are committed.
- [ ] Documentation is updated when behavior or setup changes.
- [ ] The change does not introduce telemetry or cloud dependencies.

## Commit Messages

Use a concise imperative summary, for example:

```text
Add TLS pinning integration test
Fix zero-byte transfer finalization
Harden room server with local-network limits
```

Do not include generated files unless the project requires them for the build.
