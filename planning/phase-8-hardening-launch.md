# Phase 8: Security Hardening, Performance Optimization, and Launch

## Context
- **Phases 1-7 complete:** Full-featured app with P2P transfer, rooms, and Merge Space.
- **App positioning:** "Your files never leave your Wi-Fi. No account. No ads. No cloud."
- **Targets:** Google Play Store, Apple App Store, Microsoft Store (optional), direct APK.
- **Goal:** Make the app production-ready through extensive security hardening, performance tuning, and store preparation.

---

## 8.1 Security Hardening

### 8.1.1 Transfer Encryption (TLS)
All device-to-device communication must be encrypted to prevent Man-in-the-Middle (MITM) attacks on the local network.
- **Implementation:**
  - Generate a self-signed X.509 certificate and private key per device on the first launch using `dart:io` `SecurityContext`.
  - Exchange certificate fingerprints (SHA-256) during the device discovery/pairing process (e.g., via mDNS TXT records or initial pairing handshake).
  - Configure the `shelf` HTTP server to use the generated `SecurityContext` for HTTPS communication.
  - Implement certificate pinning: clients must verify the server's certificate fingerprint matches the expected fingerprint obtained during discovery before transmitting files.

### 8.1.2 Content Validation
Prevent malicious files from being received and processed.
- **Implementation:**
  - Validate file types and sizes before accepting a transfer request.
  - Implement basic scanning for known malicious file extensions or patterns.
  - Perform SHA-256 checksum verification on the received file. The sender must provide the hash in the transfer metadata, and the receiver verifies it after the transfer completes.
  - Implement rate limiting on the `shelf` HTTP server to prevent Denial of Service (DoS) attacks from malicious apps on the same network.

### 8.1.3 Network Security
Restrict network exposure.
- **Implementation:**
  - Bind the HTTP server exclusively to local network interfaces (e.g., `192.168.x.x`), avoiding `0.0.0.0` which binds to all interfaces (including potentially public or cellular interfaces).
  - Implement middleware to validate that incoming connection IPs belong to the local network subnet.
  - Enforce timeouts on idle connections (e.g., 30 seconds).
  - Limit the number of concurrent connections to a reasonable threshold (e.g., 10-20) to prevent resource exhaustion.

### 8.1.4 Data Protection
Protect sensitive data stored on the device.
- **Implementation:**
  - Securely store device keys, group keys, and certificates using the `flutter_secure_storage` package.
  - Encrypt the local database (used for history, Merge Space metadata, etc.) using SQLCipher via the `drift` package.
  - Add an optional App Lock feature requiring a PIN or biometric authentication (Face ID, fingerprint) to open the app, utilizing the `local_auth` package.
  - Ensure sensitive data is cleared on app uninstall. On Android, explicitly set `android:allowBackup="false"` and `android:fullBackupContent="false"` in the `AndroidManifest.xml`.

---

## 8.2 Performance Optimization

### 8.2.1 Transfer Speed
Ensure high-speed file transfers.
- **Implementation:**
  - Benchmark current transfer speeds under various network conditions.
  - Implement adaptive chunk sizing based on network latency and bandwidth.
  - Enable parallel chunk uploads (sending 3-5 chunks simultaneously) instead of purely sequential transfers.
  - Tune buffer sizes for the `shelf` HTTP server and file reading/writing operations.
  - Extensively test with large files (1GB+) and large collections of small files (1000+).

### 8.2.2 Memory Management
Prevent out-of-memory (OOM) crashes.
- **Implementation:**
  - Stream files directly from disk to the network and network to disk. **Never** load entire files into memory.
  - Limit the memory footprint of thumbnail generation (e.g., scale down images, process sequentially).
  - Profile the application using Flutter DevTools Memory tab to identify and fix memory leaks.
  - Test on low-memory Android and iOS devices.

### 8.2.3 Battery Optimization
Minimize battery drain, especially during background operations.
- **Implementation:**
  - Minimize unnecessary background processing.
  - Optimize mDNS discovery by reducing the broadcast frequency when there are no active transfers or user interaction.
  - Stop discovery when the app is backgrounded, except for specific background tasks like Merge Space sync (which should use WorkManager/BGTaskScheduler efficiently).
  - Profile battery impact using Android Battery Historian and iOS Energy Gauge.

### 8.2.4 App Size
Keep the app lightweight.
- **Implementation:**
  - Analyze the APK and IPA sizes using Flutter's build size analysis tools.
  - Remove unused packages and assets.
  - Consider deferred loading for non-critical features or heavy libraries.
  - **Targets:** <30MB for Android APK, <50MB for iOS IPA.

---

## 8.3 Error Handling & Robustness

### 8.3.1 Crash Reporting
Maintain privacy while monitoring stability.
- **Implementation:**
  - **Option 1 (Default):** No crash reporting to ensure maximum privacy.
  - **Option 2:** Opt-in only crash reporting. If implemented, use a self-hosted Sentry instance or write to a local crash log that the user can manually export and share.
  - Users must explicitly opt-in via Settings.
  - **Strict Rule:** NO Firebase Crashlytics or similar third-party SDKs that send telemetry data to external servers.

### 8.3.2 Error Recovery
Ensure a smooth user experience even when things fail.
- **Implementation:**
  - Ensure every error state has a clear, user-visible message and a recovery action (e.g., "Retry").
  - For network errors during transfer, implement a retry mechanism with exponential backoff.
  - For file system errors, implement graceful degradation.
  - If permissions (e.g., storage, local network) are revoked mid-use, guide the user to the OS settings to re-enable them.
  - If the HTTP server crashes, implement an auto-restart mechanism.

### 8.3.3 Edge Case Testing
Validate the app against extreme and uncommon scenarios.
- **Scenarios to test:**
  - Transferring files with emoji or complex unicode characters in the filename.
  - Transferring 0-byte files.
  - Transferring files with very long filenames (255+ chars).
  - Transferring while the receiving/sending device goes to sleep.
  - Transferring when the device storage is nearly full.
  - Handling two devices with the exact same name on the network.
  - Rapid connect/disconnect cycles.
  - Attempting to send a file to the same device (self-send).

---

## 8.4 Accessibility
Ensure the app is usable by everyone.
- **Implementation:**
  - Add `Semantics` widgets and labels to all interactive elements.
  - Ensure sufficient color contrast across the app, aiming for WCAG AA standards.
  - Test the UI with screen readers (TalkBack on Android, VoiceOver on iOS).
  - Ensure all tap targets are at least 48x48dp.
  - Test the UI with system font scaling up to 200% to ensure layouts do not break.

---

## 8.5 Localization Preparation
Prepare the app for a global audience.
- **Implementation:**
  - Set up Flutter localization using ARB files.
  - Extract all hardcoded, user-visible strings into the `app_en.arb` file.
  - Initially support English only, but establish the structure for easily adding more languages.
  - Ensure the layout supports Right-to-Left (RTL) text rendering for future Arabic/Hebrew support.

---

## 8.6 Beta Testing

### 8.6.1 Internal Testing
Rigorous internal dogfooding.
- **Device Combinations:**
  - Android → Android (same Wi-Fi)
  - Android → iOS (same Wi-Fi)
  - iOS → Android
  - Windows → Android (if desktop is supported)
  - macOS → iOS (if desktop is supported)
- **Network Conditions:**
  - Home Wi-Fi (reliable)
  - Mobile hotspot (variable)
  - Corporate/school Wi-Fi (may block mDNS; app should fail gracefully or fallback to manual IP entry)
  - No network (should fail gracefully)

### 8.6.2 External Beta
Gather feedback from a small group of real users (10-20 users).
- **Platforms:**
  - Android: Google Play Internal Testing track.
  - iOS: TestFlight.
- **Feedback Collection:**
  - Create a beta feedback Google Form.
  - Collect data on successful transfers, failed transfers, speed impressions, UX feedback, and bugs.
- **Duration:** Run the beta for 1-2 weeks before finalizing the launch build.

---

## 8.7 App Store Preparation

### 8.7.1 Google Play Store
- **Signing:** Set up app signing (upload key + app signing key).
- **Listing Details:**
  - **Title:** "NearShare — Offline File Transfer"
  - **Short Description:** "Send files. No internet. No account. No ads."
  - **Full Description:** Highlight privacy, speed, and the no-ads differentiator.
  - **Category:** Tools or Communication.
  - **Content Rating:** Everyone.
- **Assets:** Minimum 4 screenshots (home, send flow, receive, rooms), feature graphic (1024x500).
- **Compliance:** Provide a privacy policy URL and write permissions justification text for the store console.

### 8.7.2 Apple App Store
- **Setup:** Configure App Store Connect, Certificates, Identifiers, and Provisioning Profiles.
- **Listing Details:** Similar to Play Store.
- **App Review Notes:**
  - Explicitly explain the local network usage and why it is essential.
  - Explain why no account system is required.
  - Provide a link to a demo video for the reviewer.
- **Privacy Nutrition Labels:**
  - Data NOT collected: everything.
  - Data NOT linked to you: everything.
  - Tracking: NO.

### 8.7.3 Privacy Policy
Create a clear, honest, and accessible privacy policy.
- **Key Points:**
  - "We don't collect any data. Period."
  - No telemetry, no analytics, no tracking.
  - All data stays on the device.
  - No third-party SDKs that collect data are used.
- **Hosting:** Host the privacy policy as a simple HTML or Markdown page on GitHub Pages.

---

## 8.8 Build Configuration
Set up robust CI/CD and build variants.
- **Flavors / Variants:**
  - `dev` — Debug builds with verbose logging.
  - `staging` — Beta builds with limited logging.
  - `prod` — Release builds, minified, with all logging stripped out.
- **Versioning:** Use Semantic Versioning (SemVer) starting at `1.0.0`.
- **Automation:** Set up a CI pipeline (e.g., GitHub Actions) to auto-increment the build number and sign code for all target platforms.

---

## 8.9 Documentation
Prepare public-facing documentation.
- **`README.md`:** Project overview, core features, build instructions, and a brief contributing guide.
- **`ARCHITECTURE.md`:** Technical explanation of the discovery and transfer protocols.
- **`CONTRIBUTING.md`:** Guidelines for how to contribute to the open-source project.
- **`LICENSE`:** Choose an open-source license (e.g., MIT or Apache 2.0).
- **In-app:** Add an "About" section containing the app version, links to the privacy policy, and open-source licenses.

---

## Tests

### Security Tests (Minimum 8)
1. **TLS:** Verify HTTP server rejects standard HTTP connections.
2. **TLS:** Verify certificate pinning prevents MITM attacks (simulate with a proxy).
3. **Rate Limiting:** Verify server rejects/drops requests exceeding the limit.
4. **Local Network:** Verify server ignores connection attempts from non-local IP addresses.
5. **Checksum:** Verify the app detects a corrupted file (modify bytes in transit) and fails the transfer.
6. **Encryption:** Verify Merge Space files are encrypted in transit.
7. **Secure Storage:** Verify keys are correctly stored in `flutter_secure_storage`.
8. **App Lock:** Verify biometric/PIN prompt appears when opening the app (if enabled).

### Performance Tests (Minimum 5)
1. **Transfer Speed:** Achieve >50 Mbps on a standard, uncongested Wi-Fi 5/6 network.
2. **Large File Transfer:** Successfully transfer a 1GB+ file without app crashes or UI freezes.
3. **Many Files Transfer:** Successfully transfer a batch of 100+ small files.
4. **Memory Usage:** Ensure memory stays under 200MB during large transfers (profile with DevTools).
5. **App Startup:** Ensure cold start time is under 2 seconds.

### Edge Case Tests (Minimum 8)
1. **Unicode Filename:** Transfer files with emojis/foreign characters correctly.
2. **Zero-Byte File:** App handles empty files gracefully.
3. **Long Filename:** App handles 255+ character filenames (truncates safely for UI, saves correctly).
4. **Low Storage:** App displays a proper error message when receiving a file larger than available space.
5. **Permission Revoked:** App handles background permission revocation gracefully.
6. **Same Device Name:** Two devices with the same name appear as distinguishable entities.
7. **Rapid Reconnect:** App does not crash when connecting and disconnecting rapidly.
8. **Send to Self:** App gracefully handles or prevents attempts to send files to the device itself.

### Accessibility Tests (Minimum 4)
1. **Screen Reader:** All buttons, inputs, and list items have descriptive semantics.
2. **Color Contrast:** All text passes WCAG AA contrast ratios.
3. **Tap Targets:** All interactive elements are at least 48x48dp.
4. **Font Scaling:** App UI remains functional and readable at 200% system font size.

### Store Readiness Checklist
- [ ] App icon correct sizes for all platforms (Android adaptive, iOS standard).
- [ ] Splash screen configured and working.
- [ ] All required permissions have localized justification strings.
- [ ] Privacy policy written and URL is live.
- [ ] Screenshots captured on multiple device sizes (phones, tablets).
- [ ] Store descriptions and promotional text written.
- [ ] App signed with production keys.
- [ ] Final release build runs correctly without debug banners or logging.

---

## Acceptance Criteria
- [ ] TLS encryption implemented for all device communication.
- [ ] SHA-256 checksum verification implemented on transferred files.
- [ ] Rate limiting and local-network-only binding applied on HTTP server.
- [ ] App lock (PIN/biometric) feature is working.
- [ ] Transfer speed exceeds 50 Mbps on standard local Wi-Fi.
- [ ] App size is <30MB (APK).
- [ ] App startup is <2 seconds.
- [ ] All edge cases handled without crashes.
- [ ] Accessibility requirements (screen reader, contrast, tap targets) pass.
- [ ] Localization infrastructure set up (English complete).
- [ ] Beta test with 10-20 users completed and feedback reviewed.
- [ ] Google Play Store listing prepared and ready for review.
- [ ] Apple App Store listing prepared and ready for review.
- [ ] Privacy policy written, clear, and hosted on GitHub Pages.
- [ ] README and architecture documentation complete.
- [ ] All security tests pass (minimum 8).
- [ ] All performance tests pass (minimum 5).
- [ ] All edge case tests pass (minimum 8).
- [ ] All accessibility tests pass (minimum 4).
- [ ] `flutter analyze` passes with zero issues.
- [ ] Final release build is signed and tagged `v1.0.0` in version control.
