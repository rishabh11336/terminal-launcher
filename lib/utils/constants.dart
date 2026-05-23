import 'package:flutter/material.dart';

class PrefKeys {
  static const String pinnedPackages = 'pinned_packages'; // List<String>
  static const String hiddenPackages = 'hidden_packages'; // List<String>
  static const String accentColor = 'accent_color'; // String enum name
  static const String showStatusBar = 'show_status_bar'; // bool
  static const String lockOnDoubleTap = 'lock_on_double_tap'; // bool
}

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60% opacity
  static const Color textHint = Color(0x66FFFFFF); // 40% opacity
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentAmber = Color(0xFFF59E0B);
}

class AppDurations {
  static const Duration cursorBlink = Duration(milliseconds: 530);
  static const Duration autoLaunch = Duration(milliseconds: 300);
  static const Duration searchOverlayFade = Duration(milliseconds: 100);
  static const Duration drawerTransition = Duration(milliseconds: 200);
  static const Duration clockRefresh = Duration(seconds: 30);
  static const Duration staleAppListThreshold = Duration(seconds: 60);
}

class AppSizes {
  static const double timeFontSize = 48;
  static const double dateFontSize = 14;
  static const double appNameFontSize = 18;
  static const double cursorFontSize = 16;
  static const double hintFontSize = 12;
  static const int maxPinnedApps = 5;
  static const int maxSearchResults = 6;
  static const double swipeVelocityThreshold = 200.0;
  static const double paddingH = 32;
  static const double paddingTop = 48;
  static const double paddingBottom = 32;
}
