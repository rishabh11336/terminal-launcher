import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IconCacheService {
  static final IconCacheService _instance = IconCacheService._internal();
  factory IconCacheService() => _instance;
  IconCacheService._internal();

  static const _channel = MethodChannel('com.rishabh.terminal_launcher/apps');

  // null value = tried and failed (prevents retry storms)
  final Map<String, Uint8List?> _cache = {};

  Future<Uint8List?> getIcon(String packageName) async {
    if (_cache.containsKey(packageName)) return _cache[packageName];
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      );
      _cache[packageName] = bytes;
      return bytes;
    } on PlatformException catch (e) {
      debugPrint('[IconCache] $packageName: ${e.message}');
      _cache[packageName] = null;
      return null;
    }
  }

  void evict(String packageName) => _cache.remove(packageName);

  void clear() => _cache.clear();
}
