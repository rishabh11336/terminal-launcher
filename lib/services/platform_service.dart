import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  static const _channel =
      MethodChannel('com.rishabh.terminal_launcher/platform');

  // Pull down notification shade (TRD Section 6.2)
  Future<void> expandNotifications() async {
    try {
      await _channel.invokeMethod('expandNotifications');
    } on PlatformException catch (e) {
      // Graceful degradation — hidden API may be blocked on future Android (TRD 14.1)
      debugPrint('[Platform] expandNotifications failed: ${e.message}');
    }
  }

  // Lock screen — requires device admin permission (TRD Section 6.2)
  Future<void> lockScreen() async {
    try {
      await _channel.invokeMethod('lockScreen');
    } on PlatformException catch (e) {
      debugPrint('[Platform] lockScreen failed: ${e.message}');
    }
  }
}
