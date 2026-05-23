import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/models/launcher_settings.dart';

void main() {
  group('AppInfo — equality and identity', () {
    const appA = AppInfo(
      packageName: 'com.whatsapp',
      displayName: 'WhatsApp',
      searchKey: 'whatsapp',
    );
    const appB = AppInfo(
      packageName: 'com.whatsapp',
      displayName: 'WhatsApp Business', // different name, same package
      searchKey: 'whatsapp business',
    );
    const appC = AppInfo(
      packageName: 'com.google.chrome',
      displayName: 'Chrome',
      searchKey: 'chrome',
    );

    test('equal when packageName matches regardless of displayName', () {
      expect(appA, equals(appB));
    });

    test('not equal when packageName differs', () {
      expect(appA, isNot(equals(appC)));
    });

    test('hashCode consistent with equality', () {
      expect(appA.hashCode, equals(appB.hashCode));
    });

    test('different packages have different hashCodes (likely)', () {
      expect(appA.hashCode, isNot(equals(appC.hashCode)));
    });

    test('Set deduplicates by packageName', () {
      final set = {appA, appB, appC};
      expect(set.length, equals(2));
    });

    test('List.contains works with == override', () {
      final list = [appA, appC];
      expect(list.contains(appB), isTrue); // appB same package as appA
    });
  });

  group('AppInfo — field values', () {
    const app = AppInfo(
      packageName: 'com.spotify.music',
      displayName: 'Spotify',
      searchKey: 'spotify',
    );

    test('packageName stored correctly', () {
      expect(app.packageName, equals('com.spotify.music'));
    });

    test('displayName stored correctly', () {
      expect(app.displayName, equals('Spotify'));
    });

    test('searchKey stored correctly', () {
      expect(app.searchKey, equals('spotify'));
    });

    test('searchKey is lowercase', () {
      expect(app.searchKey, equals(app.searchKey.toLowerCase()));
    });

    test('toString contains packageName', () {
      expect(app.toString(), contains('com.spotify.music'));
    });

    test('toString contains displayName', () {
      expect(app.toString(), contains('Spotify'));
    });
  });

  group('AppInfo — edge cases', () {
    test('app with empty displayName is valid', () {
      const app = AppInfo(
        packageName: 'com.test',
        displayName: '',
        searchKey: '',
      );
      expect(app.packageName, equals('com.test'));
    });

    test('searchKey with spaces is valid', () {
      const app = AppInfo(
        packageName: 'com.google.maps',
        displayName: 'Google Maps',
        searchKey: 'google maps',
      );
      expect(app.searchKey.contains(' '), isTrue);
    });

    test('app with CJK display name is valid', () {
      const app = AppInfo(
        packageName: 'com.wechat',
        displayName: '微信',
        searchKey: '微信',
      );
      expect(app.displayName, isNotEmpty);
    });
  });

  group('LauncherSettings — defaults', () {
    const s = LauncherSettings();

    test('pinnedPackages defaults to empty', () {
      expect(s.pinnedPackages, isEmpty);
    });

    test('hiddenPackages defaults to empty', () {
      expect(s.hiddenPackages, isEmpty);
    });

    test('accentColor defaults to white', () {
      expect(s.accentColor, equals(AccentColor.white));
    });

    test('showStatusBar defaults to false', () {
      expect(s.showStatusBar, isFalse);
    });

    test('lockOnDoubleTap defaults to false', () {
      expect(s.lockOnDoubleTap, isFalse);
    });
  });

  group('LauncherSettings — copyWith', () {
    const base = LauncherSettings();

    test('copyWith accentColor changes only accentColor', () {
      final s = base.copyWith(accentColor: AccentColor.green);
      expect(s.accentColor, equals(AccentColor.green));
      expect(s.showStatusBar, isFalse);
      expect(s.pinnedPackages, isEmpty);
    });

    test('copyWith showStatusBar=true', () {
      final s = base.copyWith(showStatusBar: true);
      expect(s.showStatusBar, isTrue);
      expect(s.accentColor, equals(AccentColor.white)); // unchanged
    });

    test('copyWith lockOnDoubleTap=true', () {
      final s = base.copyWith(lockOnDoubleTap: true);
      expect(s.lockOnDoubleTap, isTrue);
    });

    test('copyWith pinnedPackages', () {
      final s = base.copyWith(pinnedPackages: ['com.a', 'com.b']);
      expect(s.pinnedPackages, equals(['com.a', 'com.b']));
      expect(s.hiddenPackages, isEmpty); // unchanged
    });

    test('copyWith hiddenPackages', () {
      final s = base.copyWith(hiddenPackages: {'com.x', 'com.y'});
      expect(s.hiddenPackages.length, equals(2));
      expect(s.pinnedPackages, isEmpty); // unchanged
    });

    test('copyWith with no args returns equivalent object', () {
      final s = base.copyWith();
      expect(s, equals(base));
    });

    test('chained copyWith', () {
      final s = base
          .copyWith(accentColor: AccentColor.amber)
          .copyWith(showStatusBar: true);
      expect(s.accentColor, equals(AccentColor.amber));
      expect(s.showStatusBar, isTrue);
    });
  });

  group('LauncherSettings — equality', () {
    test('two defaults are equal', () {
      const a = LauncherSettings();
      const b = LauncherSettings();
      expect(a, equals(b));
    });

    test('different accentColor are not equal', () {
      const a = LauncherSettings(accentColor: AccentColor.green);
      const b = LauncherSettings(accentColor: AccentColor.amber);
      expect(a, isNot(equals(b)));
    });

    test('different pinnedPackages are not equal', () {
      final a = const LauncherSettings().copyWith(pinnedPackages: ['com.a']);
      final b = const LauncherSettings().copyWith(pinnedPackages: ['com.b']);
      expect(a, isNot(equals(b)));
    });

    test('different showStatusBar are not equal', () {
      const a = LauncherSettings(showStatusBar: true);
      const b = LauncherSettings(showStatusBar: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('AccentColor — color values', () {
    test('white is 0xFFFFFFFF', () {
      expect(AccentColor.white.color.toARGB32(), equals(0xFFFFFFFF));
    });

    test('green is 0xFF00FF88', () {
      expect(AccentColor.green.color.toARGB32(), equals(0xFF00FF88));
    });

    test('amber is 0xFFF59E0B', () {
      expect(AccentColor.amber.color.toARGB32(), equals(0xFFF59E0B));
    });

    test('all colors are fully opaque', () {
      for (final c in AccentColor.values) {
        expect(c.color.a, equals(1.0));
      }
    });

    test('color extension returns Color', () {
      for (final c in AccentColor.values) {
        expect(c.color, isA<Color>());
      }
    });
  });
}
