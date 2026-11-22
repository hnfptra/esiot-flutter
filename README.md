# IoT Monitor

Flutter MQTT dashboard for ESP32 temperature, humidity, and LED monitoring on Android and iOS.

## Setup

Install Flutter stable and an Android SDK. Start the app with `flutter pub get` followed by `flutter run`.
The connection screen is pre-filled with the public test broker `broker.emqx.io:1883`
(username `emqx`, password `public`). Replace those values with your broker's settings as needed.
Enable **Ingat pengaturan dan kata sandi** to persist settings and store the password in the
platform's secure storage.

Default MQTT topics (editable in **Pengaturan topik**):

| Purpose | Topic | Payload |
|---|---|---|
| Temperature | `polines/data/2015041003/sensor/suhu` | Numeric string in °C |
| Humidity | `polines/data/2015041003/sensor/humidity` | Numeric string in % |
| LED control/state | `polines/data/2015041003/led` | `1` on, `0` off |

Use QoS 0 for sensor updates and QoS 1 for LED commands. The app persists sensor history locally
for up to 30 days and displays the newest 100, last 24 hours, or last 7 days.

## Build

### Android

```bash
flutter clean
flutter pub get
flutter run
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`.

### iOS (macOS + Xcode required)

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter run
flutter build ipa --release
```

IPA output: `build/ios/ipa/*.ipa`. Before the first signed IPA build, open `ios/Runner.xcworkspace`
in Xcode, choose a development team under **Runner → Signing & Capabilities**, and let Xcode
manage signing. You can also build ad-hoc or development IPAs with
`flutter build ipa --release --export-method ad-hoc` or
`flutter build ipa --release --export-method development`.

### iOS build without a local Mac

Use a macOS CI runner (for example GitHub Actions with `macos-latest`) to run
`flutter pub get` and `flutter build ios --release --no-codesign`, then package
`build/ios/iphoneos/Runner.app` in a `Payload` directory as an unsigned IPA. Unsigned IPAs
must be re-signed before installation; App Store and TestFlight distribution require a paid
Apple Developer account.

## Checks

```bash
flutter analyze
flutter test
```

## Screenshots

_Add Android and iOS dashboard screenshots here._
