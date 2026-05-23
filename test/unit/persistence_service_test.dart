import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminal_launcher/models/launcher_settings.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/utils/constants.dart';

void main() {
  late PersistenceService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    svc = PersistenceService(prefs);
  });

  group('PersistenceService — pinnedPackages', () {
    test('returns empty list when no data', () {
      expect(svc.getPinnedPackages(), isEmpty);
    });

    test('stores and retrieves pinned packages in order', () async {
      await svc.setPinnedPackages(['com.whatsapp', 'com.google.gmail']);
      final result = svc.getPinnedPackages();
      expect(result, equals(['com.whatsapp', 'com.google.gmail']));
    });

    test('overwrites previous pinned packages', () async {
      await svc.setPinnedPackages(['com.whatsapp']);
      await svc.setPinnedPackages(['com.spotify.music', 'com.google.chrome']);
      expect(svc.getPinnedPackages().length, equals(2));
      expect(svc.getPinnedPackages().first, equals('com.spotify.music'));
    });

    test('stores empty list', () async {
      await svc.setPinnedPackages(['com.whatsapp']);
      await svc.setPinnedPackages([]);
      expect(svc.getPinnedPackages(), isEmpty);
    });
  });

  group('PersistenceService — hiddenPackages', () {
    test('returns empty set when no data', () {
      expect(svc.getHiddenPackages(), isEmpty);
    });

    test('stores and retrieves hidden packages', () async {
      await svc.setHiddenPackages({'com.facebook.katana', 'com.twitter.android'});
      final result = svc.getHiddenPackages();
      expect(result.contains('com.facebook.katana'), isTrue);
      expect(result.contains('com.twitter.android'), isTrue);
    });

    test('returns Set (no duplicates)', () async {
      // Set already deduplicates before writing
      final input = <String>{'com.test.app'};
      input.add('com.test.app'); // intentional duplicate attempt
      await svc.setHiddenPackages(input);
      expect(svc.getHiddenPackages().length, equals(1));
    });

    test('can clear hidden packages by setting empty set', () async {
      await svc.setHiddenPackages({'com.facebook.katana'});
      await svc.setHiddenPackages({});
      expect(svc.getHiddenPackages(), isEmpty);
    });
  });

  group('PersistenceService — accentColor', () {
    test('defaults to white', () {
      expect(svc.getAccentColor(), equals(AccentColor.white));
    });

    test('stores and retrieves green', () async {
      await svc.setAccentColor(AccentColor.green);
      expect(svc.getAccentColor(), equals(AccentColor.green));
    });

    test('stores and retrieves amber', () async {
      await svc.setAccentColor(AccentColor.amber);
      expect(svc.getAccentColor(), equals(AccentColor.amber));
    });

    test('returns white if stored value is invalid/corrupted', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefKeys.accentColor, 'invalid_value');
      expect(svc.getAccentColor(), equals(AccentColor.white));
    });
  });

  group('PersistenceService — showStatusBar', () {
    test('defaults to false', () {
      expect(svc.getShowStatusBar(), isFalse);
    });

    test('stores true', () async {
      await svc.setShowStatusBar(true);
      expect(svc.getShowStatusBar(), isTrue);
    });

    test('stores false after true', () async {
      await svc.setShowStatusBar(true);
      await svc.setShowStatusBar(false);
      expect(svc.getShowStatusBar(), isFalse);
    });
  });

  group('PersistenceService — lockOnDoubleTap', () {
    test('defaults to false', () {
      expect(svc.getLockOnDoubleTap(), isFalse);
    });

    test('stores true', () async {
      await svc.setLockOnDoubleTap(true);
      expect(svc.getLockOnDoubleTap(), isTrue);
    });
  });

  group('PersistenceService — loadSettings', () {
    test('returns default LauncherSettings when nothing stored', () {
      final settings = svc.loadSettings();
      expect(settings.pinnedPackages, isEmpty);
      expect(settings.hiddenPackages, isEmpty);
      expect(settings.accentColor, equals(AccentColor.white));
      expect(settings.showStatusBar, isFalse);
      expect(settings.lockOnDoubleTap, isFalse);
    });

    test('loads all stored values into LauncherSettings', () async {
      await svc.setPinnedPackages(['com.whatsapp']);
      await svc.setHiddenPackages({'com.facebook.katana'});
      await svc.setAccentColor(AccentColor.green);
      await svc.setShowStatusBar(true);
      await svc.setLockOnDoubleTap(true);

      final settings = svc.loadSettings();
      expect(settings.pinnedPackages, equals(['com.whatsapp']));
      expect(settings.hiddenPackages.contains('com.facebook.katana'), isTrue);
      expect(settings.accentColor, equals(AccentColor.green));
      expect(settings.showStatusBar, isTrue);
      expect(settings.lockOnDoubleTap, isTrue);
    });

    test('loadSettings returns LauncherSettings instance', () {
      expect(svc.loadSettings(), isA<LauncherSettings>());
    });
  });

  group('PersistenceService — static create()', () {
    test('create() returns a PersistenceService', () async {
      SharedPreferences.setMockInitialValues({});
      final service = await PersistenceService.create();
      expect(service, isA<PersistenceService>());
    });
  });
}
