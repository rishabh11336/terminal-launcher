import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  static const _channel =
      MethodChannel('com.rishabh.terminal_launcher/platform');

  Future<void> expandNotifications() async {
    try {
      await _channel.invokeMethod('expandNotifications');
    } on PlatformException catch (e) {
      debugPrint('[Platform] expandNotifications failed: ${e.message}');
    }
  }

  /// Returns true if device admin is active for LockScreenReceiver.
  Future<bool> isAdminActive() async {
    try {
      return await _channel.invokeMethod<bool>('isAdminActive') ?? false;
    } on PlatformException catch (e) {
      debugPrint('[Platform] isAdminActive failed: ${e.message}');
      return false;
    }
  }

  /// Opens Android's built-in "Activate device admin" screen.
  Future<void> openDeviceAdminSettings() async {
    try {
      await _channel.invokeMethod('openDeviceAdminSettings');
    } on PlatformException catch (e) {
      debugPrint('[Platform] openDeviceAdminSettings failed: ${e.message}');
    }
  }

  /// Locks the screen. If device admin is not active, opens the activation
  /// screen instead so the user can grant the permission.
  Future<void> lockScreen() async {
    try {
      await _channel.invokeMethod('lockScreen');
    } on PlatformException catch (e) {
      if (e.code == 'ADMIN_NOT_ACTIVE') {
        await openDeviceAdminSettings();
      } else {
        debugPrint('[Platform] lockScreen failed: ${e.message}');
      }
    }
  }
}
