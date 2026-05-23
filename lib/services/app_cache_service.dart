import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/services/persistence_service.dart';

class AppCacheService {
  // Singleton
  static final AppCacheService _instance = AppCacheService._internal();
  factory AppCacheService() => _instance;
  AppCacheService._internal();

  List<AppInfo> _allApps = [];
  List<String> _pinnedOrder = []; // ordered package names
  Set<String> _hiddenPkgs = {};

  DateTime? _lastRefresh;

  List<AppInfo> get allApps => List.unmodifiable(_allApps);
  Set<String> get hiddenPackages => Set.unmodifiable(_hiddenPkgs);

  List<AppInfo> get pinnedApps {
    return _pinnedOrder
        .map((pkg) {
          try {
            return _allApps.firstWhere((a) => a.packageName == pkg);
          } catch (_) {
            return null; // app was uninstalled (EC-05)
          }
        })
        .whereType<AppInfo>()
        .toList();
  }

  // Called once at app start — awaited before showing any UI
  Future<void> initialize(PersistenceService prefs) async {
    await _loadApps();
    _pinnedOrder = prefs.getPinnedPackages();
    _hiddenPkgs = prefs.getHiddenPackages();
    _lastRefresh = DateTime.now();
  }

  Future<void> _loadApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: false, // critical: no icon loading (TRD NFR-04)
      onlyAppsWithLaunchIntent: true,
    );

    // Retry once if empty (TRD Section 14.1 edge case)
    if (apps.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('[AppCache] Empty app list on first load — retrying');
      apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: true,
        includeAppIcons: false,
        onlyAppsWithLaunchIntent: true,
      );
    }

    // Sort on background isolate to avoid jank (TRD Section 12.3)
    final rawList = apps.map((a) {
      try {
        return AppInfo.fromApplication(a);
      } catch (_) {
        return null; // skip malformed manifests (EC-12)
      }
    }).whereType<AppInfo>().toList();

    _allApps = await compute(_sortApps, rawList);
    debugPrint('[AppCache] Loaded ${_allApps.length} apps');
  }

  static List<AppInfo> _sortApps(List<AppInfo> apps) {
    return apps..sort((a, b) => a.searchKey.compareTo(b.searchKey));
  }

  // Re-query full list — called on resume if > 60s since last refresh
  Future<void> refresh(PersistenceService prefs) async {
    debugPrint('[AppCache] Refreshing app list');
    await _loadApps();
    _lastRefresh = DateTime.now();
  }

  bool get isStale {
    if (_lastRefresh == null) return true;
    return DateTime.now().difference(_lastRefresh!) >
        const Duration(seconds: 60);
  }

  // Called by EventChannel when package is installed
  void onPackageAdded(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName);
      if (app != null) {
        final info = AppInfo.fromApplication(app);
        _allApps = [..._allApps, info]
          ..sort((a, b) => a.searchKey.compareTo(b.searchKey));
        debugPrint('[AppCache] Added: $packageName');
      }
    } catch (e) {
      debugPrint('[AppCache] onPackageAdded error for $packageName: $e');
    }
  }

  // Called by EventChannel when package is uninstalled
  void onPackageRemoved(String packageName) {
    _allApps = _allApps.where((a) => a.packageName != packageName).toList();
    _pinnedOrder.remove(packageName);
    _hiddenPkgs.remove(packageName);
    debugPrint('[AppCache] Removed: $packageName');
  }

  // Debug only: seed fake apps when device_apps returns nothing (emulator)
  void seedDebugApps() {
    _allApps = const [
      AppInfo(packageName: 'com.whatsapp', displayName: 'WhatsApp', searchKey: 'whatsapp'),
      AppInfo(packageName: 'com.google.android.youtube', displayName: 'YouTube', searchKey: 'youtube'),
      AppInfo(packageName: 'com.google.chrome', displayName: 'Chrome', searchKey: 'chrome'),
      AppInfo(packageName: 'com.spotify.music', displayName: 'Spotify', searchKey: 'spotify'),
      AppInfo(packageName: 'com.google.android.gm', displayName: 'Gmail', searchKey: 'gmail'),
      AppInfo(packageName: 'com.google.maps', displayName: 'Google Maps', searchKey: 'google maps'),
      AppInfo(packageName: 'com.android.camera', displayName: 'Camera', searchKey: 'camera'),
      AppInfo(packageName: 'com.notion.id', displayName: 'Notion', searchKey: 'notion'),
      AppInfo(packageName: 'com.instagram.android', displayName: 'Instagram', searchKey: 'instagram'),
      AppInfo(packageName: 'com.twitter.android', displayName: 'Twitter', searchKey: 'twitter'),
      AppInfo(packageName: 'com.netflix.mediaclient', displayName: 'Netflix', searchKey: 'netflix'),
      AppInfo(packageName: 'com.slack', displayName: 'Slack', searchKey: 'slack'),
      AppInfo(packageName: 'com.telegram.messenger', displayName: 'Telegram', searchKey: 'telegram'),
      AppInfo(packageName: 'com.google.android.keep', displayName: 'Keep Notes', searchKey: 'keep notes'),
      AppInfo(packageName: 'com.google.android.calendar', displayName: 'Calendar', searchKey: 'calendar'),
    ];
  }

  // Settings mutations (called from LauncherNotifier)
  void updatePinnedOrder(List<String> ordered) {
    _pinnedOrder = List.from(ordered);
  }

  void updateHiddenPackages(Set<String> hidden) {
    _hiddenPkgs = Set.from(hidden);
  }
}
