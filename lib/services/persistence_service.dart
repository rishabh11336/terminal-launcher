import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminal_launcher/models/launcher_settings.dart';
import 'package:terminal_launcher/utils/constants.dart';

class PersistenceService {
  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  static Future<PersistenceService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService(prefs);
  }

  // --- Pinned packages ---

  List<String> getPinnedPackages() =>
      _prefs.getStringList(PrefKeys.pinnedPackages) ?? [];

  Future<void> setPinnedPackages(List<String> pkgs) =>
      _prefs.setStringList(PrefKeys.pinnedPackages, pkgs);

  // --- Hidden packages ---

  Set<String> getHiddenPackages() =>
      (_prefs.getStringList(PrefKeys.hiddenPackages) ?? []).toSet();

  Future<void> setHiddenPackages(Set<String> pkgs) =>
      _prefs.setStringList(PrefKeys.hiddenPackages, pkgs.toList());

  // --- Accent color ---

  AccentColor getAccentColor() {
    final name = _prefs.getString(PrefKeys.accentColor);
    if (name == null) return AccentColor.white;
    return AccentColor.values.firstWhere(
      (c) => c.name == name,
      orElse: () => AccentColor.white,
    );
  }

  Future<void> setAccentColor(AccentColor color) =>
      _prefs.setString(PrefKeys.accentColor, color.name);

  // --- Status bar toggle ---

  bool getShowStatusBar() =>
      _prefs.getBool(PrefKeys.showStatusBar) ?? false;

  Future<void> setShowStatusBar(bool value) =>
      _prefs.setBool(PrefKeys.showStatusBar, value);

  // --- Double-tap lock ---

  bool getLockOnDoubleTap() =>
      _prefs.getBool(PrefKeys.lockOnDoubleTap) ?? false;

  Future<void> setLockOnDoubleTap(bool value) =>
      _prefs.setBool(PrefKeys.lockOnDoubleTap, value);

  // --- Load full settings object ---

  LauncherSettings loadSettings() => LauncherSettings(
        pinnedPackages: getPinnedPackages(),
        hiddenPackages: getHiddenPackages(),
        accentColor: getAccentColor(),
        showStatusBar: getShowStatusBar(),
        lockOnDoubleTap: getLockOnDoubleTap(),
      );
}
