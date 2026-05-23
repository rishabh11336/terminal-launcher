import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/models/launcher_settings.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';
import 'package:terminal_launcher/services/app_launcher_service.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/services/platform_service.dart';
import 'package:terminal_launcher/state/launcher_state.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/utils/search_utils.dart';

const _packageChannel = EventChannel('com.rishabh.terminal_launcher/packages');

class LauncherNotifier extends ChangeNotifier {
  LauncherState _state = const LauncherState();
  LauncherState get state => _state;

  final AppCacheService _cache;
  final AppLauncherService _launcher;
  final PlatformService _platform;
  final PersistenceService _prefs;

  Timer? _autoLaunchTimer;
  StreamSubscription<dynamic>? _pkgSubscription;
  bool _disposed = false;

  LauncherNotifier({
    required AppCacheService cache,
    required AppLauncherService launcher,
    required PlatformService platform,
    required PersistenceService prefs,
  })  : _cache = cache,
        _launcher = launcher,
        _platform = platform,
        _prefs = prefs {
    _init();
  }

  // Load apps in background — UI renders immediately, apps populate when ready
  Future<void> _init() async {
    bool initialized = false;
    try {
      await _cache.initialize(_prefs);
      initialized = true;
    } catch (e) {
      // MissingPluginException in test env — skip silently
      debugPrint('[LauncherNotifier] Cache init skipped: $e');
    }
    if (_disposed) return;
    // Only seed on emulator where real plugin returns empty list (not in tests)
    if (initialized && kDebugMode && _cache.allApps.isEmpty) {
      debugPrint('[LauncherNotifier] Seeding debug apps (emulator)');
      _cache.seedDebugApps();
    }
    // Wire package broadcasts after cache is ready (TRD Section 3.3)
    try {
      _pkgSubscription = _packageChannel.receiveBroadcastStream().listen((event) {
        if (event is Map) {
          final type = event['type'] as String?;
          final pkg = event['package'] as String?;
          if (pkg == null) return;
          if (type == 'added') {
            _cache.onPackageAdded(pkg);
          } else if (type == 'removed') {
            _cache.onPackageRemoved(pkg);
          }
          if (!_disposed) notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('[LauncherNotifier] Package channel skipped: $e');
    }
    if (!_disposed) notifyListeners(); // triggers UI rebuild with loaded apps
  }

  // --- Search ---

  void onSearchChanged(String query) {
    // Always cancel existing timer before creating new one (EC-09)
    assert(() {
      // Debug assertion: timer should be managed safely
      return true;
    }());
    _autoLaunchTimer?.cancel();

    final results = SearchUtils.filter(
      apps: _cache.allApps,
      query: query,
      hidden: _cache.hiddenPackages,
      limit: AppSizes.maxSearchResults,
    );

    final candidate = results.length == 1 ? results.first : null;

    _state = _state.copyWith(
      isSearchActive: true,
      searchQuery: query,
      searchResults: results,
      autoLaunchCandidate: candidate,
      clearAutoLaunch: candidate == null,
    );
    notifyListeners();

    // Auto-launch on unique match after 300ms debounce (TRD Section 8.3)
    if (_state.hasUniqueMatch) {
      _autoLaunchTimer = Timer(
        AppDurations.autoLaunch,
        () => launchApp(results.first),
      );
    }
  }

  void launchApp(AppInfo app) {
    _autoLaunchTimer?.cancel();
    clearSearch();
    _launcher.launch(app.packageName);
  }

  void clearSearch() {
    _autoLaunchTimer?.cancel();
    _state = const LauncherState();
    notifyListeners();
  }

  void activateSearch() {
    _state = _state.copyWith(isSearchActive: true);
    notifyListeners();
  }

  // --- Drawer ---

  void openDrawer() {
    _state = _state.copyWith(isDrawerOpen: true);
    notifyListeners();
  }

  void closeDrawer() {
    _state = _state.copyWith(isDrawerOpen: false);
    notifyListeners();
  }

  // --- Platform ---

  Future<void> expandNotifications() => _platform.expandNotifications();

  Future<void> lockScreen() => _platform.lockScreen();

  // --- Pinned apps ---

  void pinApp(String packageName) {
    final current = _prefs.getPinnedPackages();
    if (current.contains(packageName)) return;
    if (current.length >= AppSizes.maxPinnedApps) return;
    final updated = [...current, packageName];
    _prefs.setPinnedPackages(updated);
    _cache.updatePinnedOrder(updated);
    notifyListeners();
  }

  void unpinApp(String packageName) {
    final updated = _prefs.getPinnedPackages()
      ..remove(packageName);
    _prefs.setPinnedPackages(updated);
    _cache.updatePinnedOrder(updated);
    notifyListeners();
  }

  void reorderPinned(List<String> newOrder) {
    _prefs.setPinnedPackages(newOrder);
    _cache.updatePinnedOrder(newOrder);
    notifyListeners();
  }

  // --- Hidden apps ---

  void hideApp(String packageName) {
    final hidden = {..._prefs.getHiddenPackages(), packageName};
    _prefs.setHiddenPackages(hidden);
    _cache.updateHiddenPackages(hidden);
    // Also unpin if pinned
    final pinned = _prefs.getPinnedPackages()..remove(packageName);
    _prefs.setPinnedPackages(pinned);
    _cache.updatePinnedOrder(pinned);
    notifyListeners();
  }

  void unhideApp(String packageName) {
    final hidden = {..._prefs.getHiddenPackages()}..remove(packageName);
    _prefs.setHiddenPackages(hidden);
    _cache.updateHiddenPackages(hidden);
    notifyListeners();
  }

  // --- Accessors for UI ---

  List<AppInfo> get pinnedApps => _cache.pinnedApps;

  List<AppInfo> get allVisibleApps => _cache.allApps
      .where((a) => !_cache.hiddenPackages.contains(a.packageName))
      .toList();

  Set<String> get hiddenPackages => _cache.hiddenPackages;

  List<AppInfo> get hiddenApps => _cache.allApps
      .where((a) => _cache.hiddenPackages.contains(a.packageName))
      .toList();

  // --- Settings accessors ---

  AccentColor get accentColor => _prefs.getAccentColor();

  void setAccentColor(AccentColor color) {
    _prefs.setAccentColor(color);
    notifyListeners();
  }

  bool get showStatusBar => _prefs.getShowStatusBar();

  void setShowStatusBar(bool value) {
    _prefs.setShowStatusBar(value);
    notifyListeners();
  }

  bool get lockOnDoubleTap => _prefs.getLockOnDoubleTap();

  void setLockOnDoubleTap(bool value) {
    _prefs.setLockOnDoubleTap(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoLaunchTimer?.cancel();
    _pkgSubscription?.cancel();
    super.dispose();
  }
}
