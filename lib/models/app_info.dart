import 'package:flutter/foundation.dart';
import 'package:device_apps/device_apps.dart';

@immutable
class AppInfo {
  final String packageName; // e.g. "com.whatsapp"
  final String displayName; // e.g. "WhatsApp"
  final String searchKey; // e.g. "whatsapp" (lowercase, trimmed)

  const AppInfo({
    required this.packageName,
    required this.displayName,
    required this.searchKey,
  });

  // No icon stored — keeps cache well under 5MB for 200+ apps (TRD NFR-04)
  factory AppInfo.fromApplication(Application app) {
    return AppInfo(
      packageName: app.packageName,
      displayName: app.appName,
      searchKey: app.appName.toLowerCase().trim(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppInfo && other.packageName == packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => 'AppInfo($packageName, "$displayName")';
}
