import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _method = MethodChannel('com.rishabh.terminal_launcher/notifications');
  static const _events = EventChannel('com.rishabh.terminal_launcher/notification_counts');

  Future<bool> isPermissionGranted() async {
    try {
      return await _method.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _method.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      debugPrint('[Notif] requestPermission failed: ${e.message}');
    }
  }

  // late final: created once, asBroadcastStream() allows multiple listeners
  // (LauncherNotifier + NotificationsTable) without cancelling each other
  late final Stream<Map<String, int>> countStream = _events
      .receiveBroadcastStream()
      .map((event) {
        if (event is Map) {
          return event.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
        return <String, int>{};
      })
      .asBroadcastStream();
}
