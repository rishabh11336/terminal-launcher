import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum AccentColor { white, green, amber }

extension AccentColorValue on AccentColor {
  Color get color => switch (this) {
        AccentColor.white => const Color(0xFFFFFFFF),
        AccentColor.green => const Color(0xFF00FF88),
        AccentColor.amber => const Color(0xFFF59E0B),
      };
}

@immutable
class LauncherSettings {
  final List<String> pinnedPackages; // ordered list of package names
  final Set<String> hiddenPackages; // unordered set, O(1) lookup
  final AccentColor accentColor;
  final bool showStatusBar; // battery + wifi display
  final bool lockOnDoubleTap;

  const LauncherSettings({
    this.pinnedPackages = const [],
    this.hiddenPackages = const {},
    this.accentColor = AccentColor.white,
    this.showStatusBar = false,
    this.lockOnDoubleTap = false,
  });

  LauncherSettings copyWith({
    List<String>? pinnedPackages,
    Set<String>? hiddenPackages,
    AccentColor? accentColor,
    bool? showStatusBar,
    bool? lockOnDoubleTap,
  }) =>
      LauncherSettings(
        pinnedPackages: pinnedPackages ?? this.pinnedPackages,
        hiddenPackages: hiddenPackages ?? this.hiddenPackages,
        accentColor: accentColor ?? this.accentColor,
        showStatusBar: showStatusBar ?? this.showStatusBar,
        lockOnDoubleTap: lockOnDoubleTap ?? this.lockOnDoubleTap,
      );

  @override
  bool operator ==(Object other) =>
      other is LauncherSettings &&
      listEquals(other.pinnedPackages, pinnedPackages) &&
      setEquals(other.hiddenPackages, hiddenPackages) &&
      other.accentColor == accentColor &&
      other.showStatusBar == showStatusBar &&
      other.lockOnDoubleTap == lockOnDoubleTap;

  @override
  int get hashCode => Object.hash(
        pinnedPackages,
        hiddenPackages,
        accentColor,
        showStatusBar,
        lockOnDoubleTap,
      );
}
