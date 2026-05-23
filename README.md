# Terminal Launcher

A minimalistic Android home screen replacement built for developers who want their phone to feel like a terminal.

True black. No icons. Text only. Instant search.

---

## Features

- **True black OLED display** — `#000000` everywhere, zero grays
- **Clock + date** in JetBrains Mono
- **Pinned apps** — up to 5, shown as plain text
- **Instant search** — tap anywhere, type to filter all installed apps
  - Auto-launches after 300ms when only one match remains
  - Prefix-prioritized scoring: exact → prefix → word-boundary → substring
- **App drawer** — swipe up, scroll the full app list, tap to open
- **Notification shade** — swipe down
- **Long press** → settings
- **Double-tap** → lock screen (optional, toggle in settings)
- **Pin / hide apps** via long-press context menu on any app
- **Optional status bar** — battery % + network type (top-right)
- **Accent color** — green (default) or amber

---

## Gestures

| Gesture | Action |
|---|---|
| Tap | Activate search |
| Swipe up | Open app drawer |
| Swipe down | Pull notification shade |
| Long press | Open settings |
| Double tap | Lock screen (if enabled in settings) |
| Back button | Close search / dismiss drawer |

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter 3.22+ / Dart 3.4+ |
| State management | `provider` + `ChangeNotifier` |
| Persistence | `shared_preferences` |
| App listing | `device_apps` |
| Font | JetBrains Mono (bundled) |
| Platform | Android only |
| Native layer | Kotlin — app query, notification shade, lock screen |

---

## Architecture

```
lib/
├── main.dart                   # Entry — runApp immediately, apps load async
├── models/
│   ├── app_info.dart           # Immutable app model
│   └── launcher_settings.dart  # AccentColor enum
├── services/
│   ├── app_cache_service.dart  # Singleton in-memory app list (no icons)
│   ├── app_launcher_service.dart
│   ├── persistence_service.dart
│   └── platform_service.dart
├── state/
│   ├── launcher_state.dart     # Immutable state (copyWith pattern)
│   └── launcher_notifier.dart  # ChangeNotifier — single source of truth
├── screens/
│   ├── home_screen.dart
│   ├── app_drawer_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── clock_widget.dart
│   ├── terminal_cursor.dart
│   ├── pinned_apps_list.dart
│   ├── search_overlay.dart
│   ├── app_list_tile.dart
│   ├── context_menu.dart
│   └── status_bar_widget.dart
└── utils/
    ├── search_utils.dart       # 4-tier scoring search algorithm
    └── constants.dart
```

### Performance design

- `runApp()` fires immediately — UI visible before app list finishes loading
- `AppCacheService` singleton holds app list in memory — zero disk I/O on search path
- `Offstage(TextField)` always mounted in widget tree — eliminates 100–200ms keyboard delay on search activation
- Only the search results widget rebuilds on keystrokes — clock, pinned apps, and cursor are const
- App list refreshes only on `PACKAGE_ADDED` / `PACKAGE_REMOVED` broadcast — no polling

---

## Building

**Requirements:**
- Flutter 3.22+
- Android SDK (API 34+)
- Java 17

```bash
# Clone
git clone <repo-url>
cd terminal_launcher

# Install dependencies
flutter pub get

# Run (debug, emulator)
flutter run

# Release APK — arm64 only (Pixel 7a)
flutter build apk --release --target-platform android-arm64
# → build/app/outputs/flutter-apk/app-release.apk
```

---

## Installation (Pixel 7a)

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Then: **Settings → Apps → Default apps → Home app → Terminal Launcher**

> If the app list is empty: Settings → Apps → Terminal Launcher → Permissions → grant **Display over other apps** / package visibility.

---

## Tests

```bash
flutter test
# 225 tests — unit + widget
```

---

## Device

Built for **Google Pixel 7a** (Android 14). Works on any Android device API 26+.

Personal project — not on the Play Store. Sideloaded APK only.
