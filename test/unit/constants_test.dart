import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/utils/constants.dart';

void main() {
  group('PrefKeys', () {
    test('all keys are non-empty strings', () {
      expect(PrefKeys.pinnedPackages, isNotEmpty);
      expect(PrefKeys.hiddenPackages, isNotEmpty);
      expect(PrefKeys.accentColor, isNotEmpty);
      expect(PrefKeys.showStatusBar, isNotEmpty);
      expect(PrefKeys.lockOnDoubleTap, isNotEmpty);
    });

    test('all keys are unique', () {
      final keys = [
        PrefKeys.pinnedPackages,
        PrefKeys.hiddenPackages,
        PrefKeys.accentColor,
        PrefKeys.showStatusBar,
        PrefKeys.lockOnDoubleTap,
      ];
      expect(keys.toSet().length, equals(keys.length));
    });

    test('key values match expected strings', () {
      expect(PrefKeys.pinnedPackages, equals('pinned_packages'));
      expect(PrefKeys.hiddenPackages, equals('hidden_packages'));
      expect(PrefKeys.accentColor, equals('accent_color'));
      expect(PrefKeys.showStatusBar, equals('show_status_bar'));
      expect(PrefKeys.lockOnDoubleTap, equals('lock_on_double_tap'));
    });
  });

  group('AppColors', () {
    test('background is pure black', () {
      expect(AppColors.background, equals(const Color(0xFF000000)));
    });

    test('textPrimary is pure white', () {
      expect(AppColors.textPrimary, equals(const Color(0xFFFFFFFF)));
    });

    test('textSecondary is 60% opacity white', () {
      expect(AppColors.textSecondary, equals(const Color(0x99FFFFFF)));
    });

    test('textHint is 40% opacity white', () {
      expect(AppColors.textHint, equals(const Color(0x66FFFFFF)));
    });

    test('accentGreen matches TRD spec', () {
      expect(AppColors.accentGreen, equals(const Color(0xFF00FF88)));
    });

    test('accentAmber matches TRD spec', () {
      expect(AppColors.accentAmber, equals(const Color(0xFFF59E0B)));
    });
  });

  group('AppDurations', () {
    test('cursorBlink is 530ms', () {
      expect(AppDurations.cursorBlink.inMilliseconds, equals(530));
    });

    test('autoLaunch debounce is 300ms', () {
      expect(AppDurations.autoLaunch.inMilliseconds, equals(300));
    });

    test('searchOverlayFade is 100ms', () {
      expect(AppDurations.searchOverlayFade.inMilliseconds, equals(100));
    });

    test('drawerTransition is 200ms', () {
      expect(AppDurations.drawerTransition.inMilliseconds, equals(200));
    });

    test('clockRefresh is 30s', () {
      expect(AppDurations.clockRefresh.inSeconds, equals(30));
    });

    test('staleAppListThreshold is 60s', () {
      expect(AppDurations.staleAppListThreshold.inSeconds, equals(60));
    });
  });

  group('AppSizes', () {
    test('timeFontSize is 48', () {
      expect(AppSizes.timeFontSize, equals(48));
    });

    test('appNameFontSize is 18', () {
      expect(AppSizes.appNameFontSize, equals(18));
    });

    test('cursorFontSize is 16', () {
      expect(AppSizes.cursorFontSize, equals(16));
    });

    test('maxPinnedApps is 5', () {
      expect(AppSizes.maxPinnedApps, equals(5));
    });

    test('maxSearchResults is 6', () {
      expect(AppSizes.maxSearchResults, equals(6));
    });

    test('swipeVelocityThreshold is 200', () {
      expect(AppSizes.swipeVelocityThreshold, equals(200.0));
    });
  });
}
