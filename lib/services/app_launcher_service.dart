import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';

class AppLauncherService {
  Future<void> launch(String packageName) async {
    try {
      await DeviceApps.openApp(packageName);
    } catch (e) {
      debugPrint('[Launcher] Failed to launch $packageName: $e');
    }
  }
}
