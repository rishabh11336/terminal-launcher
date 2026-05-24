class RecentAppInfo {
  final String packageName;
  final String appName;
  final int lastUsed; // epoch ms

  const RecentAppInfo({
    required this.packageName,
    required this.appName,
    required this.lastUsed,
  });

  factory RecentAppInfo.fromMap(Map<Object?, Object?> map) {
    return RecentAppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      lastUsed: map['lastUsed'] as int,
    );
  }
}
