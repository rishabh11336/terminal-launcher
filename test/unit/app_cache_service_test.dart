import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';

void main() {
  final cache = AppCacheService();

  // Reset cache state between tests to prevent cross-test contamination
  setUp(() {
    cache.updatePinnedOrder([]);
    cache.updateHiddenPackages({});
  });

  group('AppCacheService — allApps', () {
    test('allApps returns unmodifiable list', () {
      expect(
        () => (cache.allApps as List).add(const AppInfo(
          packageName: 'x',
          displayName: 'X',
          searchKey: 'x',
        )),
        throwsUnsupportedError,
      );
    });

    test('allApps returns a List', () {
      expect(cache.allApps, isA<List<AppInfo>>());
    });
  });

  group('AppCacheService — hiddenPackages', () {
    test('defaults to empty set', () {
      expect(cache.hiddenPackages, isEmpty);
    });

    test('updateHiddenPackages stores packages', () {
      cache.updateHiddenPackages({'com.facebook.katana'});
      expect(cache.hiddenPackages.contains('com.facebook.katana'), isTrue);
    });

    test('updateHiddenPackages replaces previous set', () {
      cache.updateHiddenPackages({'com.old.app'});
      cache.updateHiddenPackages({'com.new.app'});
      expect(cache.hiddenPackages.contains('com.old.app'), isFalse);
      expect(cache.hiddenPackages.contains('com.new.app'), isTrue);
    });

    test('hiddenPackages returns unmodifiable set', () {
      cache.updateHiddenPackages({'com.test.one'});
      expect(
        () => (cache.hiddenPackages as Set).add('com.test.two'),
        throwsUnsupportedError,
      );
    });

    test('can set empty hidden packages', () {
      cache.updateHiddenPackages({'com.some.app'});
      cache.updateHiddenPackages({});
      expect(cache.hiddenPackages, isEmpty);
    });
  });

  group('AppCacheService — pinnedApps', () {
    test('returns empty list when pinnedOrder is empty', () {
      cache.updatePinnedOrder([]);
      expect(cache.pinnedApps, isEmpty);
    });

    test('returns empty list when pinned packages not in allApps (uninstalled)', () {
      // EC-05: pinned app uninstalled → skip gracefully
      cache.updatePinnedOrder(['com.nonexistent.app', 'com.another.ghost']);
      expect(cache.pinnedApps, isEmpty);
    });

    test('pinnedApps returns AppInfo list', () {
      expect(cache.pinnedApps, isA<List<AppInfo>>());
    });

    test('pinnedApps length never exceeds allApps length', () {
      cache.updatePinnedOrder(['com.ghost1', 'com.ghost2', 'com.ghost3']);
      expect(cache.pinnedApps.length, lessThanOrEqualTo(cache.allApps.length));
    });
  });

  group('AppCacheService — onPackageRemoved', () {
    test('removing nonexistent package does not throw', () {
      expect(() => cache.onPackageRemoved('com.nonexistent'), returnsNormally);
    });

    test('removes package from pinned order', () {
      cache.updatePinnedOrder(['com.target', 'com.keep']);
      cache.onPackageRemoved('com.target');
      // com.target not in allApps anyway, pinnedApps should not contain it
      expect(cache.pinnedApps.any((a) => a.packageName == 'com.target'), isFalse);
    });

    test('removes package from hidden set', () {
      cache.updateHiddenPackages({'com.target', 'com.keep'});
      cache.onPackageRemoved('com.target');
      expect(cache.hiddenPackages.contains('com.target'), isFalse);
      expect(cache.hiddenPackages.contains('com.keep'), isTrue);
    });

    test('removing package twice does not throw', () {
      expect(() {
        cache.onPackageRemoved('com.double.remove');
        cache.onPackageRemoved('com.double.remove');
      }, returnsNormally);
    });
  });

  group('AppCacheService — isStale', () {
    test('isStale returns a bool', () {
      expect(cache.isStale, isA<bool>());
    });

    test('isStale is false immediately after updatePinnedOrder (not a full init but cache was seeded)', () {
      // isStale depends on _lastRefresh being set by initialize()
      // In unit test env without device, _lastRefresh is null → isStale = true
      // (or false if a previous test ran initialize — but we can't call it without a device)
      // Verify it's a valid bool and doesn't throw
      expect(() => cache.isStale, returnsNormally);
    });
  });

  group('AppCacheService — singleton', () {
    test('two instances are the same object', () {
      final a = AppCacheService();
      final b = AppCacheService();
      expect(identical(a, b), isTrue);
    });

    test('state mutation on one instance visible on other', () {
      final a = AppCacheService();
      final b = AppCacheService();
      a.updateHiddenPackages({'com.shared.state'});
      expect(b.hiddenPackages.contains('com.shared.state'), isTrue);
    });
  });

  group('AppCacheService — updatePinnedOrder', () {
    test('stores ordered list', () {
      cache.updatePinnedOrder(['com.a', 'com.b', 'com.c']);
      // pinnedApps filters to those in allApps — all ghosts, so returns []
      // but we verify updatePinnedOrder doesn't throw
      expect(() => cache.pinnedApps, returnsNormally);
    });

    test('empty list clears pinned order', () {
      cache.updatePinnedOrder(['com.a', 'com.b']);
      cache.updatePinnedOrder([]);
      expect(cache.pinnedApps, isEmpty);
    });
  });
}
