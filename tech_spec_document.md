# Technical Specification: Flutter MQTT IoT Dashboard (Liquid Glass UI, Android + iOS)

> **Instruction to AI agent:** Build the complete Flutter application described in this document inside the current folder. Create the project with `flutter create --org com.polines --project-name mqtt_iot_dashboard .` if no Flutter project exists yet. Implement every section, run `flutter pub get` and `flutter analyze`, and fix all errors and warnings before finishing. Do NOT ask clarifying questions; use the defaults in this document.

---

## 1. System Overview

A mobile MQTT client app (Android and iOS) that talks to an ESP32 microcontroller through an MQTT broker. The app lets the user:

- log in to the broker with host, port, username and password,
- monitor temperature and humidity in real time,
- control an LED on the ESP32 (1 = ON, 0 = OFF),
- receive rule-based smart suggestions from the sensor data,
- store every reading in a local SQLite database,
- view historical trends in interactive charts.

**Target platforms:** Android and iOS only. **Do not target Flutter Web** (`mqtt_client`'s `MqttServerClient` uses `dart:io` sockets and throws `Unsupported operation: default SecurityContext getter` on web). Use `MqttServerClient` only.

---

## 2. Technology Stack

| Purpose | Package |
|---|---|
| Framework | Flutter (stable channel), Dart 3+ |
| MQTT | `mqtt_client` (use `MqttServerClient`) |
| Local DB | `sqflite` + `path` |
| Charts | `fl_chart` |
| State management | `provider` (ChangeNotifier) |
| Settings storage | `shared_preferences` (host, port, username, client id, topics) |
| Secret storage | `flutter_secure_storage` (password; uses Keychain on iOS, Keystore on Android) |
| Date formatting | `intl` |
| Haptics | `flutter/services.dart` (`HapticFeedback`) |

Use the latest versions compatible with the installed Flutter SDK (`flutter pub add <pkg>`). Do not hardcode old versions.

**Liquid glass rendering:** implement it with a custom reusable widget (`BackdropFilter` + gradients), see section 7. Do not depend on third-party glass packages, so the build stays reliable on both platforms.

---

## 3. MQTT Communication Protocol

All topics must be **configurable in Settings** (stored in `shared_preferences`) with these defaults:

### Subscribe (incoming from ESP32)

| Data | Default topic | Payload |
|---|---|---|
| Temperature | `polines/data/2015041003/sensor/suhu` | numeric string, e.g. `"25.4"` (°C) |
| Humidity | `polines/data/2015041003/sensor/humidity` | numeric string, e.g. `"60.2"` (%) |

### Publish (outgoing to ESP32)

| Data | Default topic | Payload |
|---|---|---|
| LED control | `polines/data/2015041003/led` | `"1"` = ON, `"0"` = OFF |

Rules:

- Parse payloads with `double.tryParse(payload.trim())`. Ignore invalid payloads (do not crash, do not insert into DB).
- Also subscribe to the LED topic so the switch reflects the real state if another client changes it (e.g. MQTT Explorer publishes `1`).
- QoS 0 for sensor topics, QoS 1 for the LED publish. Do not use `retain` for the LED publish by default.
- Connection settings: `keepAlivePeriod = 30`, `autoReconnect = true`, `resubscribeOnAutoReconnect = true`, `logging(on: false)`, protocol `MqttClientConstants.mqttV311`, unique client id (default `flutter_` + random 6 chars, editable).
- Test broker defaults (pre-filled in the form): host `broker.emqx.io`, port `1883`, username `emqx`, password `public`.
- Connection timeout 10 seconds. Show a clear error message on failure (wrong credentials, host unreachable, timeout).

---

## 4. Main Features

1. **Connection Setup Screen (login form):** fields Broker Host, Port, Username, Password (obscured with show/hide), Client ID. Buttons: **Connect**. Option "Remember me" saves everything (password in secure storage). If saved credentials exist, pre-fill the form. Show a loading state while connecting and a glass snackbar on error.
2. **Real-time subscription:** after connect, auto-subscribe to all topics and update the UI live.
3. **LED control panel:** a glass toggle switch. Toggling publishes `1`/`0`, with haptic feedback, and shows "LED menyala" / "LED mati" and the last command time.
4. **Smart suggestions:** rule engine (section 4.1) that updates a banner with color and icon by severity.
5. **Automatic history logging:** every valid sensor update is written to SQLite with a timestamp.
6. **Analytics dashboard:** line charts for temperature and humidity, range filter (**100 terbaru**, **24 jam**, **7 hari**), summary stats (average temperature, average humidity, number of data points), clear-history action with confirmation.
7. **Disconnect:** a power button in the top bar disconnects safely and returns to the Connection Setup Screen.
8. **Connection status:** a "Live" / "Offline" glass chip in the app bar, plus a status card showing broker address and last data received time.

### 4.1 Suggestion rules (evaluate temperature and humidity together, show all that apply, most severe first)

| Condition | Severity | Message (Indonesian) |
|---|---|---|
| temp < 16 | warning | "Suhu {t}°C sangat dingin. Hindari paparan langsung dan gunakan penghangat bila diperlukan." |
| 16 ≤ temp < 20 | info | "Suhu {t}°C cukup dingin." |
| 20 ≤ temp ≤ 30 | good | "Suhu {t}°C berada pada rentang nyaman." |
| 30 < temp ≤ 35 | warning | "Suhu {t}°C cukup panas. Pertimbangkan menyalakan kipas atau AC." |
| temp > 35 | danger | "Suhu {t}°C sangat panas! Segera dinginkan ruangan dan pastikan hidrasi." |
| hum < 30 | warning | "Kelembapan {h}% sangat rendah. Gunakan humidifier atau tambahkan tanaman." |
| 30 ≤ hum < 40 | info | "Kelembapan {h}% agak kering." |
| 40 ≤ hum ≤ 60 | good | "Kelembapan {h}% ideal." |
| 60 < hum ≤ 75 | info | "Kelembapan {h}% agak lembap. Pastikan sirkulasi udara baik." |
| hum > 75 | warning | "Kelembapan {h}% sangat tinggi. Nyalakan dehumidifier dan periksa sirkulasi udara." |
| no data yet | neutral | "Menunggu data sensor..." |

Put thresholds as constants in one file so they are easy to change. Implement as a pure function (`List<Suggestion> evaluate(double? t, double? h)`) so it is unit-testable.

---

## 5. Application Flow

1. **Launch:** load saved settings. If none, show the Connection Setup Screen with test-broker defaults.
2. **Connect:** validate form (non-empty host, port 1-65535) → connect → on success subscribe to topics and navigate to the Main Shell (replace route). On failure show error and stay on the form.
3. **Main Shell:** floating glass bottom navigation with two tabs: **Dashboard** and **Analitik**. Top bar: title "IoT Monitor", Live chip, disconnect button.
4. **Dashboard tab (top to bottom):**
   - Connection status card (broker, last data time)
   - Section "Kondisi ruangan" with two big glass metric cards: Suhu (°C) and Kelembapan (%)
   - Suggestion banner (color-coded)
   - LED control card with switch
   - Small footer row: "Riwayat tersimpan otomatis • {time}"
5. **Data persistence (background):** keep `latestTemp` and `latestHum` in the provider. On each valid incoming sensor message, update the matching value; once **both** values have been received at least once, insert a row `(timestamp, temperature, humidity)` using the new value plus the latest value of the other sensor. (This ensures a row is stored for every update, not only when both arrive in the same instant.)
6. **Analitik tab:** range chips → query DB → draw charts. Header stats row. Each chart is in its own glass card, with min–max badge.
7. **Disconnect:** stop MQTT, clear in-memory live values, navigate to the Connection Setup Screen. Keep DB data.
8. **Reconnect handling:** on unexpected disconnect show the Live chip as "Offline" (amber) and let auto-reconnect work; show a glass snackbar "Koneksi terputus, mencoba menyambung kembali...".

---

## 6. Database Schema (SQLite via sqflite)

### Table: `sensor_history`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique id |
| `timestamp` | TEXT | NOT NULL | ISO 8601 local time, e.g. `2026-11-16T06:15:00` |
| `temperature` | REAL | NOT NULL | Parsed from MQTT payload |
| `humidity` | REAL | NOT NULL | Parsed from MQTT payload |

Create an index: `CREATE INDEX idx_sensor_history_timestamp ON sensor_history(timestamp);`

### Operations

- **Insert:** `INSERT INTO sensor_history (timestamp, temperature, humidity) VALUES (?, ?, ?)`
- **Latest N:** `SELECT * FROM sensor_history ORDER BY timestamp DESC LIMIT 100` → **reverse the list to ascending order before charting** (charts must go oldest → newest, left → right).
- **Range query:** `SELECT * FROM sensor_history WHERE timestamp >= ? ORDER BY timestamp ASC` (24 jam / 7 hari).
- **Stats:** average temperature, average humidity, count over the selected result set.
- **Clear:** `DELETE FROM sensor_history`.
- Retention: auto-delete rows older than 30 days on app start.
- The DB must be a singleton and opened once. Run DB writes asynchronously, never block the UI thread.

---

## 7. UI / UX: Apple "Liquid Glass" Design

Goal: a translucent, light-refracting glass look inspired by Apple's Liquid Glass (iOS 26): layered translucent surfaces, soft blur, bright specular edges, fluid spring animations. It must look identical on Android and iOS (rendered by Flutter, not native).

### 7.1 Background

Glass only looks like glass when there is something colorful behind it. Use a full-screen animated gradient background (`lib/widgets/glass_background.dart`):

- Base: vertical gradient (light mode `#EAF2FF → #F6EEFF`, dark mode `#0B1020 → #1A1033`).
- 3 large blurred color blobs (circles, radius ~140-200) in teal `#4FD1C5`, violet `#9F7AEA`, orange `#F6AD55`, drifting very slowly using `AnimationController` (20-30 s loops, `Curves.easeInOut`, repeat reverse). Blobs are drawn with `ImageFiltered(blur)` or radial gradients (prefer radial gradients for performance).
- Wrap the animated layer in `RepaintBoundary`.

### 7.2 `GlassContainer` reusable widget (`lib/widgets/glass_container.dart`)

Parameters: `child`, `borderRadius` (default 28), `blur` (default 24), `tint` (Color?, optional accent), `padding`, `opacity` (default 0.18), `onTap`.

Build with:

1. `ClipRRect(borderRadius)` →
2. `BackdropFilter(ImageFilter.blur(sigmaX: blur, sigmaY: blur))` →
3. `DecoratedBox` with:
   - fill: `LinearGradient` top-left → bottom-right, `Colors.white` alpha `opacity + 0.10` → `opacity - 0.06` (dark mode use white alpha 0.10 → 0.04), blended with optional `tint` at alpha 0.12,
   - border: 1.2 px gradient border (white alpha 0.65 top-left fading to alpha 0.10 bottom-right) to imitate the specular rim light (implement with a `CustomPainter` or nested containers),
   - shadow: `BoxShadow(color: black alpha 0.08, blurRadius: 30, offset: (0, 12))`, applied outside the clip (wrap in an outer `Container`),
   - inner highlight: a subtle top-edge white gradient overlay (height ~40%, alpha 0.18 → 0).
4. Press feedback: when `onTap` is set, scale to 0.97 with a spring-like curve (`Curves.easeOutBack`, 180 ms).

Limit the number of simultaneous `BackdropFilter`s per screen (≤ 8) and wrap each glass card in `RepaintBoundary`.

### 7.3 Component styling

- **Metric cards (Suhu / Kelembapan):** `GlassContainer` tinted orange (temperature) and blue (humidity), large number (font size 44, weight 700) with a small unit, small icon in a circular glass chip, subtle live-dot indicator that pulses on every new message.
- **Suggestion banner:** `GlassContainer` tinted by severity (good = green, info = blue, warning = amber, danger = red, neutral = grey) with icon + text; animate changes with `AnimatedSwitcher` (fade + slight slide).
- **LED control card:** glass card, bulb icon that glows (yellow `BoxShadow` blur) when ON, an adaptive switch (`Switch.adaptive` styled with an active track color of amber) or a custom glass pill toggle with a sliding knob (spring animation).
- **Bottom navigation:** floating pill, `GlassContainer` radius 32, margin 16 from the edges and above the safe area, selected tab shown by a sliding glass "lens" indicator (slightly brighter glass that animates between tabs with `AnimatedAlign`).
- **App bar:** transparent, no elevation, title left, Live chip (glass pill with green dot) and a power icon button (glass circle) on the right.
- **Inputs (connection form):** glass text fields (filled with white alpha 0.15, 20 px radius, 1 px light border, focus border white alpha 0.8), floating labels, primary **Connect** button as a glass pill with accent gradient tint and a loading spinner state.
- **Chips (range filter):** glass pills; selected chip has a stronger tint and bolder text.
- **Charts (`fl_chart`):** inside glass cards; curved lines (`isCurved: true`, `curveSmoothness: 0.25`), gradient line color, area fill gradient fading to transparent, dots only on touch, glass tooltip (rounded, white alpha 0.85 background), faint dashed grid lines, axis labels using `HH:mm`. Auto min/max Y with 10% padding. Temperature = orange, Humidity = teal/blue.
- **Snackbars / dialogs:** custom glass snackbar (floating, rounded 20, blurred) and glass confirmation dialog for "Hapus riwayat".

### 7.4 Typography, color, motion

- Font: system font. On iOS the default is San Francisco, on Android use `Roboto`. Do not add network fonts. Use weights 400/600/700, slightly negative letter spacing on large numbers (-0.5).
- Support **light and dark mode** following the system (`ThemeMode.system`). Define colors in `lib/theme/app_theme.dart`, with Material 3 enabled.
- Text colors: primary `#10223A` (light) / `#F2F6FF` (dark); secondary at 60% alpha. Make sure contrast stays readable on glass.
- Animations: entry stagger (fade + 12 px slide-up, 40 ms between cards), number changes animate with `TweenAnimationBuilder<double>`, tab changes cross-fade. Use `HapticFeedback.lightImpact()` on switch toggle and tab change.
- Use `SafeArea` everywhere (Dynamic Island / notch / Android gesture bar), and respect `MediaQuery.padding.bottom` for the floating nav.
- UI language: **Indonesian** (labels: "Kondisi ruangan", "Suhu", "Kelembapan", "Kontrol LED", "Analitik", "Broker terhubung", "Riwayat tersimpan otomatis", etc.). Code, comments and identifiers in English.

---

## 8. Project Structure

```
lib/
├── main.dart                      # App entry, providers, theme, routing
├── theme/
│   └── app_theme.dart             # Light/dark ThemeData, color tokens
├── models/
│   ├── sensor_data.dart           # SensorData (id, timestamp, temperature, humidity)
│   ├── mqtt_settings.dart         # Host, port, user, clientId, topics
│   └── suggestion.dart            # Suggestion + Severity enum
├── services/
│   ├── mqtt_service.dart          # MqttServerClient wrapper (connect, subscribe, publish, streams)
│   ├── database_service.dart      # sqflite singleton, CRUD, stats
│   └── settings_service.dart      # shared_preferences + secure storage
├── providers/
│   ├── mqtt_provider.dart         # Connection state, live values, LED state
│   └── history_provider.dart      # Range filter, chart data, stats
├── logic/
│   └── suggestion_engine.dart     # Pure rule function + thresholds
├── widgets/
│   ├── glass_background.dart
│   ├── glass_container.dart
│   ├── glass_button.dart
│   ├── glass_text_field.dart
│   ├── glass_snackbar.dart
│   ├── glass_bottom_nav.dart
│   ├── metric_card.dart
│   ├── suggestion_banner.dart
│   ├── led_control_card.dart
│   └── sensor_chart.dart
└── screens/
    ├── connection_screen.dart
    ├── main_shell.dart            # Top bar + tabs + floating nav
    ├── dashboard_tab.dart
    └── analytics_tab.dart
test/
└── suggestion_engine_test.dart
```

---

## 9. Android Configuration

- `android/app/src/main/AndroidManifest.xml`: add `<uses-permission android:name="android.permission.INTERNET"/>` (and `ACCESS_NETWORK_STATE`).
- `minSdkVersion` 21 or higher (use `flutter.minSdkVersion`), and make sure `sqflite` and `flutter_secure_storage` requirements are satisfied (`flutter_secure_storage` may need minSdk 23, set `minSdk = 23` if the build complains).
- Cleartext TCP on port 1883 is a raw socket, not HTTP, so no network security config is required.
- App label: "IoT Monitor".

---

## 10. iOS Configuration (REQUIRED, the project will also be built as an IPA)

Apply all of the following so `flutter build ipa` works.

### 10.1 Deployment target and Podfile

- Set the iOS deployment target to **13.0** everywhere.
- `ios/Podfile`: first line `platform :ios, '13.0'`.
- In `ios/Runner.xcodeproj/project.pbxproj` make sure every `IPHONEOS_DEPLOYMENT_TARGET = 13.0;`.
- Keep the default `post_install` block with `flutter_additional_ios_build_settings(target)`, and add inside it:
  ```ruby
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  end
  ```
- Then run `cd ios && pod install --repo-update` (only possible on macOS).

### 10.2 `ios/Runner/Info.plist`

Set / add these keys:

```xml
<key>CFBundleDisplayName</key>
<string>IoT Monitor</string>
<key>CFBundleName</key>
<string>mqtt_iot_dashboard</string>

<!-- Local network access: needed when the MQTT broker is on the LAN (e.g. 10.x.x.x / 192.168.x.x) -->
<key>NSLocalNetworkUsageDescription</key>
<string>Aplikasi membutuhkan akses jaringan lokal untuk terhubung ke MQTT broker di jaringan Anda.</string>
<key>NSBonjourServices</key>
<array>
  <string>_mqtt._tcp</string>
</array>

<!-- Allows plain-text connections used for non-TLS test brokers -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>

<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

Notes:
- iOS shows a "Local Network" permission prompt the first time the app connects to a LAN broker. The user must tap **Allow**, otherwise the connection to `10.x.x.x` hosts silently fails. Mention this in the in-app connection error message for iOS (`Platform.isIOS`): "Pastikan izin Jaringan Lokal diaktifkan di Pengaturan iOS."
- Remove unused `UISupportedInterfaceOrientations~ipad` entries only if they cause validation errors. Keep portrait as the main orientation for iPhone.

### 10.3 Bundle identifier, signing, icons

- Bundle ID: `com.polines.mqttiotdashboard` (editable). Set `PRODUCT_BUNDLE_IDENTIFIER` in all three build configurations (Debug, Release, Profile).
- Signing is configured by the user in Xcode (Runner target → Signing & Capabilities → Team). Do not hardcode a team id. Leave `DEVELOPMENT_TEAM` empty.
- Generate app icons for both platforms using `flutter_launcher_icons` (dev dependency) with a placeholder 1024×1024 glass-style icon (gradient teal → violet background with a white thermometer/chip symbol). Config in `pubspec.yaml` with `ios: true`, `android: true`, `remove_alpha_ios: true` (App Store icons must not have an alpha channel).
- Launch screen: keep the default storyboard but set its background color to the same value as the app's gradient start color.

### 10.4 Secure storage on iOS

`flutter_secure_storage` uses the Keychain. Use `IOSOptions(accessibility: KeychainAccessibility.first_unlock)`. No extra entitlement is required for a single app.

---

## 11. Build Instructions (include these in `README.md`)

### Android

```bash
flutter clean
flutter pub get
flutter run                      # debug on device/emulator
flutter build apk --release      # output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (requires macOS + Xcode)

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter run                      # debug on simulator/device

# Release IPA signed with your Apple Developer account
flutter build ipa --release
# output: build/ios/ipa/*.ipa

# Ad-hoc / development distribution
flutter build ipa --release --export-method ad-hoc
flutter build ipa --release --export-method development
```

Before the first IPA build, open `ios/Runner.xcworkspace` in Xcode once → Runner target → **Signing & Capabilities** → choose your Team and let Xcode manage signing.

### iOS without a local Mac (CI option)

Create `.github/workflows/ios-build.yml`:

```yaml
name: Build iOS (unsigned IPA)
on:
  workflow_dispatch:
  push:
    branches: [main]
jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      - name: Package unsigned IPA
        run: |
          mkdir -p Payload
          cp -R build/ios/iphoneos/Runner.app Payload/
          zip -r app-unsigned.ipa Payload
      - uses: actions/upload-artifact@v4
        with:
          name: ios-unsigned-ipa
          path: app-unsigned.ipa
```

The unsigned IPA can be re-signed and installed with tools such as Sideloadly or AltStore using a free or paid Apple ID. For TestFlight / App Store, use a signed build (`flutter build ipa`) with a paid Apple Developer account.

---

## 12. Error Handling & Edge Cases

- Never crash on malformed payloads, null values, or an empty database (charts show an empty-state glass card: "Belum ada data").
- Dispose subscriptions, controllers and the MQTT client properly (`dispose()` in providers/states). Avoid `setState` after dispose (`if (!mounted) return;`).
- Debounce UI rebuilds for sensors that publish faster than 5 messages/second (update UI at most every 200 ms, but still store every row).
- Limit the chart to a maximum of 300 points (downsample by taking every n-th point for 24 jam / 7 hari ranges).
- Handle app lifecycle: when the app returns from background and MQTT is disconnected, try to reconnect once automatically.
- All user-facing errors are shown through the glass snackbar, never raw exception text.

---

## 13. Testing Checklist (manual, with MQTT Explorer or MQTTX)

Broker: `broker.emqx.io`, port `1883`, username `emqx`, password `public`.

1. Connect from the app → Live chip turns green.
2. Publish `30` to `polines/data/2015041003/sensor/suhu` and `60` to `polines/data/2015041003/sensor/humidity` → cards update instantly, suggestion banner shows "nyaman" / "ideal", a row is saved.
3. Publish `12.2` (suhu) and `82.4` (humidity) → banner shows the cold and very-humid warnings.
4. Toggle the LED switch in the app → the client subscribed to `polines/data/2015041003/led` receives `1` / `0`.
5. Publish `1` / `0` to the LED topic from MQTT Explorer → the app's switch follows.
6. Open **Analitik** → charts show the points in chronological order, stats are correct, range filters work.
7. Kill the network briefly → Live chip becomes "Offline", then recovers automatically.
8. Press disconnect → returns to the Connection Setup Screen, and history is still there after reconnecting.
9. Check light mode and dark mode, a small phone (360 px wide) and a notch/Dynamic Island iPhone.

## 14. Definition of Done

- `flutter analyze` reports no issues, and `flutter test` passes (at least suggestion-engine unit tests).
- App runs on Android (and iOS simulator/device on macOS) with all features above.
- UI follows the liquid glass spec in section 7 in both light and dark mode.
- iOS project is configured per section 10, and `flutter build ipa --release` succeeds on macOS with a valid signing team.
- `README.md` contains setup, topic list, build steps (Android, iOS, CI), and a screenshot placeholder section.
