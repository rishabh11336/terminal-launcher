import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';
import 'package:terminal_launcher/services/app_launcher_service.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/services/platform_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';

// --- Minimal stubs ---

class _FakeLauncher extends AppLauncherService {
  final List<String> launched = [];
  @override
  Future<void> launch(String packageName) async {
    launched.add(packageName);
  }
}

class _FakePlatform extends PlatformService {
  int expandCount = 0;
  int lockCount = 0;
  @override
  Future<void> expandNotifications() async => expandCount++;
  @override
  Future<void> lockScreen() async => lockCount++;
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LauncherNotifier notifier;
  late _FakeLauncher launcher;
  late _FakePlatform platform;
  late PersistenceService prefs;
  late AppCacheService cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PersistenceService.create();
    cache = AppCacheService();
    // Reset singleton state
    cache.updatePinnedOrder([]);
    cache.updateHiddenPackages({});

    launcher = _FakeLauncher();
    platform = _FakePlatform();
    notifier = LauncherNotifier(
      cache: cache,
      launcher: launcher,
      platform: platform,
      prefs: prefs,
    );
  });

  tearDown(() {
    try {
      notifier.dispose();
    } catch (_) {
      // Already disposed in test
    }
  });

  group('LauncherNotifier — initial state', () {
    test('starts with default LauncherState', () {
      expect(notifier.state.isSearchActive, isFalse);
      expect(notifier.state.searchQuery, equals(''));
      expect(notifier.state.searchResults, isEmpty);
      expect(notifier.state.isDrawerOpen, isFalse);
    });

    test('pinnedApps returns empty list initially', () {
      expect(notifier.pinnedApps, isEmpty);
    });

    test('allVisibleApps excludes hidden packages', () {
      cache.updateHiddenPackages({'com.facebook.katana'});
      final visible = notifier.allVisibleApps;
      expect(visible.any((a) => a.packageName == 'com.facebook.katana'), isFalse);
    });
  });

  group('LauncherNotifier — search', () {
    test('onSearchChanged sets isSearchActive=true', () {
      notifier.onSearchChanged('wh');
      expect(notifier.state.isSearchActive, isTrue);
    });

    test('onSearchChanged stores query', () {
      notifier.onSearchChanged('wh');
      expect(notifier.state.searchQuery, equals('wh'));
    });

    test('onSearchChanged with empty string clears results', () {
      notifier.onSearchChanged('wh');
      notifier.onSearchChanged('');
      expect(notifier.state.searchResults, isEmpty);
    });

    test('clearSearch resets to default state', () {
      notifier.onSearchChanged('wh');
      notifier.clearSearch();
      expect(notifier.state.isSearchActive, isFalse);
      expect(notifier.state.searchQuery, equals(''));
      expect(notifier.state.searchResults, isEmpty);
    });

    test('activateSearch sets isSearchActive without changing query', () {
      notifier.activateSearch();
      expect(notifier.state.isSearchActive, isTrue);
      expect(notifier.state.searchQuery, equals(''));
    });

    test('notifyListeners called on onSearchChanged', () {
      int callCount = 0;
      notifier.addListener(() => callCount++);
      notifier.onSearchChanged('wh');
      expect(callCount, greaterThan(0));
    });

    test('notifyListeners called on clearSearch', () {
      int callCount = 0;
      notifier.addListener(() => callCount++);
      notifier.clearSearch();
      expect(callCount, greaterThan(0));
    });
  });

  group('LauncherNotifier — auto-launch timer', () {
    test('onSearchChanged cancels previous timer on consecutive calls', () async {
      // If timer not cancelled properly, it would fire and launchApp twice
      notifier.onSearchChanged('sp');
      notifier.onSearchChanged('spo'); // should cancel previous timer
      notifier.onSearchChanged('spot');
      notifier.onSearchChanged('spoti');
      notifier.onSearchChanged('spotif');
      notifier.onSearchChanged('spotify');

      // Wait for auto-launch debounce
      await Future.delayed(const Duration(milliseconds: 400));

      // Should have been launched at most once (last query matched spotify)
      expect(launcher.launched.length, lessThanOrEqualTo(1));
    });

    test('clearSearch cancels auto-launch timer', () async {
      notifier.onSearchChanged('spotify'); // unique match potentially
      notifier.clearSearch(); // cancel before 300ms

      await Future.delayed(const Duration(milliseconds: 400));
      // Timer was cancelled — no launch
      expect(launcher.launched, isEmpty);
    });
  });

  group('LauncherNotifier — launchApp', () {
    test('launchApp calls AppLauncherService', () {
      const app = AppInfo(
        packageName: 'com.whatsapp',
        displayName: 'WhatsApp',
        searchKey: 'whatsapp',
      );
      notifier.launchApp(app);
      expect(launcher.launched, contains('com.whatsapp'));
    });

    test('launchApp clears search state', () {
      notifier.onSearchChanged('wh');
      const app = AppInfo(
          packageName: 'com.whatsapp', displayName: 'WhatsApp', searchKey: 'whatsapp');
      notifier.launchApp(app);
      expect(notifier.state.isSearchActive, isFalse);
      expect(notifier.state.searchQuery, equals(''));
    });
  });

  group('LauncherNotifier — drawer', () {
    test('openDrawer sets isDrawerOpen=true', () {
      notifier.openDrawer();
      expect(notifier.state.isDrawerOpen, isTrue);
    });

    test('closeDrawer sets isDrawerOpen=false', () {
      notifier.openDrawer();
      notifier.closeDrawer();
      expect(notifier.state.isDrawerOpen, isFalse);
    });

    test('openDrawer notifies listeners', () {
      int count = 0;
      notifier.addListener(() => count++);
      notifier.openDrawer();
      expect(count, greaterThan(0));
    });
  });

  group('LauncherNotifier — platform', () {
    test('expandNotifications calls platform service', () async {
      await notifier.expandNotifications();
      expect(platform.expandCount, equals(1));
    });

    test('lockScreen calls platform service', () async {
      await notifier.lockScreen();
      expect(platform.lockCount, equals(1));
    });
  });

  group('LauncherNotifier — pinApp', () {
    test('pinApp adds to pinnedApps via prefs', () {
      // Seed a real app into cache first
      cache.updatePinnedOrder([]);
      // Can't add to allApps directly (no device), but pinApp stores to prefs
      notifier.pinApp('com.whatsapp');
      expect(prefs.getPinnedPackages(), contains('com.whatsapp'));
    });

    test('pinApp respects maxPinnedApps (5)', () {
      for (int i = 0; i < 7; i++) {
        notifier.pinApp('com.app.$i');
      }
      expect(prefs.getPinnedPackages().length, lessThanOrEqualTo(5));
    });

    test('pinApp does not duplicate', () {
      notifier.pinApp('com.whatsapp');
      notifier.pinApp('com.whatsapp');
      expect(
        prefs.getPinnedPackages().where((p) => p == 'com.whatsapp').length,
        equals(1),
      );
    });
  });

  group('LauncherNotifier — unpinApp', () {
    test('unpinApp removes from prefs', () {
      notifier.pinApp('com.whatsapp');
      notifier.unpinApp('com.whatsapp');
      expect(prefs.getPinnedPackages(), isNot(contains('com.whatsapp')));
    });

    test('unpinApp on non-pinned app does not throw', () {
      expect(() => notifier.unpinApp('com.nonexistent'), returnsNormally);
    });
  });

  group('LauncherNotifier — hideApp', () {
    test('hideApp adds to hidden packages', () {
      notifier.hideApp('com.facebook.katana');
      expect(prefs.getHiddenPackages(), contains('com.facebook.katana'));
    });

    test('hideApp also unpins the app', () {
      notifier.pinApp('com.facebook.katana');
      notifier.hideApp('com.facebook.katana');
      expect(prefs.getPinnedPackages(), isNot(contains('com.facebook.katana')));
      expect(prefs.getHiddenPackages(), contains('com.facebook.katana'));
    });

    test('hideApp notifies listeners', () {
      int count = 0;
      notifier.addListener(() => count++);
      notifier.hideApp('com.facebook.katana');
      expect(count, greaterThan(0));
    });
  });

  group('LauncherNotifier — unhideApp', () {
    test('unhideApp removes from hidden packages', () {
      notifier.hideApp('com.facebook.katana');
      notifier.unhideApp('com.facebook.katana');
      expect(prefs.getHiddenPackages(), isNot(contains('com.facebook.katana')));
    });

    test('unhideApp on non-hidden app does not throw', () {
      expect(() => notifier.unhideApp('com.nonexistent'), returnsNormally);
    });
  });

  group('LauncherNotifier — reorderPinned', () {
    test('reorderPinned updates prefs order', () {
      notifier.pinApp('com.a');
      notifier.pinApp('com.b');
      notifier.reorderPinned(['com.b', 'com.a']);
      expect(prefs.getPinnedPackages(), equals(['com.b', 'com.a']));
    });
  });

  group('LauncherNotifier — dispose', () {
    test('dispose cancels timers without throwing', () {
      notifier.onSearchChanged('sp'); // starts timer
      expect(() => notifier.dispose(), returnsNormally);
    });
  });
}
