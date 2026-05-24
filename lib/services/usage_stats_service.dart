import 'package:flutter/services.dart';
import 'package:terminal_launcher/models/recent_app_info.dart';

class UsageStatsService {
  static const _channel = MethodChannel('com.rishabh.terminal_launcher/usagestats');

  Future<bool> isPermissionGranted() async {
    return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
  }

  Future<void> requestPermission() async {
    await _channel.invokeMethod('requestPermission');
  }

  Future<List<RecentAppInfo>> getRecentApps({int count = 3}) async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('getRecentApps', {'count': count});
    if (raw == null) return [];
    return raw.map(RecentAppInfo.fromMap).toList();
  }
}
