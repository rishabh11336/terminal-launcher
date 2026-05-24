# Terminal Launcher — Progress Log

## Project
Android home screen replacement for Google Pixel 7a (Android 14+).
Flutter 3.22+ / Dart 3.4+ · Personal sideloaded APK · No Play Store.

---

## Release History

| Version | Date | Status | Notes |
|---|---|---|---|
| v1.0.0+1 | 2026-05-24 | ✅ Installable | Icons + settings toggle |
| v1.0.0+2 | 2026-05-24 | ❌ Play Protect blocked | Notification service added |
| v1.0.0+3 | 2026-05-24 | ❌ Play Protect blocked | Manifest metadata fix (insufficient) |
| v1.0.0+4 | 2026-05-24 | ✅ Installable | Notification service removed from manifest |

---

## Completed Work

### 1. README Compatibility Update
- Changed `Android 8.0+` → `Android 14+ (API 34+)` throughout
- Added OEM skin caveat (Samsung One UI, MIUI gesture conflicts)
- Generalized installation section from Pixel 7a-only to any Android 14+
- Added universal APK build command alongside arm64

---

### 2. App Icons (Grayscale 2D)

**Native (Kotlin):**
- `AppQueryPlugin.kt` — added `getAppIcon(packageName)` method
  - Uses `PackageManager.getApplicationIcon()` → draws to `Bitmap` → compresses PNG → returns `ByteArray`
  - Calls `bitmap.recycle()` after compression to prevent memory leaks

**Flutter services:**
- `lib/services/icon_cache_service.dart` (new)
  - Singleton `Map<String, Uint8List?>` cache
  - `null` sentinel value prevents retry storms on failed icons
  - `evict()` and `clear()` for cache management

**Flutter widgets:**
- `lib/widgets/app_icon_widget.dart` (new)
  - `StatefulWidget` — loads async, `setState` on completion
  - Grayscale via `ColorFilter.matrix` (luminosity method) — terminal aesthetic
  - `ClipRRect(radius: 4)` on icon
  - `notifCount` badge overlay — green circle, top-right corner, "9+" cap
  - `SizedBox` placeholder while loading (no layout shift)
  - `didUpdateWidget` guard for package name changes

**Settings integration:**
- `LauncherSettings` — added `showIcons: bool` (default `true`)
- `PrefKeys.showIcons` — `'show_icons'` key in SharedPreferences
- `PersistenceService` — `getShowIcons()` / `setShowIcons()`
- `LauncherNotifier` — `showIcons` getter + `setShowIcons()` with `notifyListeners()`
- Settings screen — "app icons" toggle in behaviour section

**UI call sites updated:**
- `AppListTile` — `showIcons` param, icon + 10px gap before app name
- `PinnedAppsList` — `showIcons` + `notifCount` params
- `HomeScreen` — passes `notifier.showIcons` + `notifier.notifCount`
- `SearchOverlay` — passes `notifier.showIcons`
- `AppDrawerScreen` — passes `notifier.showIcons`

---

### 3. Bug Fix — App Drawer Back Button

**Problem:** Pressing back in drawer required 2 presses — first dismissed keyboard (IME consumed it), second dismissed drawer.

**Fix:** `AppDrawerScreen` changed from `canPop: true` to `canPop: false` with explicit handler:
```dart
onPopInvokedWithResult: (_, __) {
  _focusNode.unfocus();
  Navigator.pop(context);
}
```
Single back press now always closes drawer regardless of keyboard state.

---

### 4. Bug Fix — Search Back to Clock Screen

**Problem:** Back from search required 2 presses — Android IME consumed first back (keyboard close), Flutter `PopScope` never fired. User stuck on search overlay with no keyboard.

**Root cause:** Android IME back-press is handled at OS level before Flutter's `PopScope` sees it.

**Fix:** Added `FocusNode` listener in `HomeScreen.initState()`:
```dart
_focusNode.addListener(_onFocusChanged);

void _onFocusChanged() {
  if (!_focusNode.hasFocus && (_notifier?.state.isSearchActive ?? false)) {
    _deactivateSearch();
  }
}
```
When keyboard dismissal loses focus mid-search → immediately deactivates search. One back press returns to clock screen.

---

### 5. Notification Badges (Partial — manifest disabled)

**Implemented but disabled in manifest due to Play Protect:**

- `NotificationCountService.kt` — `NotificationListenerService` subclass
  - Rebuilds `Map<String, Int>` count on every notification post/remove
  - Pushes updates on main thread via `Handler(Looper.getMainLooper())`
- `NotificationPlugin.kt` — MethodChannel + EventChannel
  - Methods: `isPermissionGranted`, `requestPermission`, `getCounts`
  - EventChannel pushes live count map to Flutter on change
- `lib/services/notification_service.dart` — Flutter singleton
  - `isPermissionGranted()`, `requestPermission()`, `countStream`
- `LauncherNotifier` — subscribes to stream, `notifCount(pkg)` getter
- Settings screen — `_NotifPermissionRow` widget (check + request permission)
- `AppIconWidget` — badge renders when `notifCount > 0`

**Why disabled:** `BIND_NOTIFICATION_LISTENER_SERVICE` + `QUERY_ALL_PACKAGES` triggers Play Protect "data stealing" block on file-share APK installs. Service declaration removed from `AndroidManifest.xml` in v1.0.0+4. Code preserved for future ADB-install builds.

---

### 6. Release Script

**File:** `terminal_launcher/release.sh`

**Behaviour:**
- Reads `version` from `pubspec.yaml` (e.g. `1.0.0+3`)
- Auto-increments build number (`+3` → `+4`)
- Writes new version back to `pubspec.yaml`
- Runs `flutter build apk --release --target-platform android-arm64`
- Copies versioned APK to `releases/terminal_launcher_v<version>.apk`
- Each run creates a new file — never overwrites

**Usage:**
```bash
bash release.sh
```

---

## Current Architecture State

### Native (Kotlin)
| File | Purpose |
|---|---|
| `AppQueryPlugin.kt` | App list query + launch + icon fetch |
| `StatusBarPlugin.kt` | Notification shade expand |
| `LockScreenPlugin.kt` | Lock screen via device admin |
| `PackageEventPlugin.kt` | EventChannel for pkg install/remove |
| `PackageBroadcastReceiver.kt` | Receives PACKAGE_ADDED/REMOVED |
| `LockScreenReceiver.kt` | Device admin receiver |
| `NotificationCountService.kt` | Notification listener (code present, manifest disabled) |
| `NotificationPlugin.kt` | Notification method+event channels (code present, manifest disabled) |

### Flutter Services
| File | Purpose |
|---|---|
| `app_cache_service.dart` | Singleton in-memory app list |
| `app_launcher_service.dart` | Launches apps via platform channel |
| `platform_service.dart` | Notification shade + lock screen |
| `persistence_service.dart` | SharedPreferences wrapper |
| `icon_cache_service.dart` | In-memory icon byte cache |
| `notification_service.dart` | Notification count stream (inactive) |

### Flutter Widgets
| File | Purpose |
|---|---|
| `app_icon_widget.dart` | Async icon load, grayscale, badge overlay |
| `app_list_tile.dart` | Single app row with optional icon |
| `pinned_apps_list.dart` | Home screen pinned apps with icons + badges |
| `search_overlay.dart` | Search results list |
| `clock_widget.dart` | Time + date display |
| `terminal_cursor.dart` | Blinking `>_` |
| `status_bar_widget.dart` | Battery + network (optional) |
| `context_menu.dart` | Long-press pin/hide menu |

---

## Pending / Planned

### Clock Screen Enhancements (awaiting user review)
- **Recent Apps** — `UsageStatsManager` → last N apps + relative timestamps
- **Notification Info** — blocked by Play Protect; requires ADB install if re-enabled

### Open Questions
1. Recent apps — count (3/5/custom)?
2. Recent apps — icon + name + time, or text-only?
3. Notifications — accept ADB-only build or skip?
4. Layout order — recent above or below pinned?
5. Section headers — show `recent` / `notifications` labels?

---

## Test Status
- **225 / 225 tests passing** (unit + widget)
- `flutter analyze` — 0 errors (1 pre-existing info in `main.dart`)
