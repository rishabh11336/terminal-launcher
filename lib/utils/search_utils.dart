import 'package:terminal_launcher/models/app_info.dart';

class SearchUtils {
  static List<AppInfo> filter({
    required List<AppInfo> apps,
    required String query,
    required Set<String> hidden,
    int limit = 6,
  }) {
    if (query.isEmpty) return const [];

    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];

    // Step 1: exclude hidden apps
    final visible = apps.where((a) => !hidden.contains(a.packageName));

    // Step 2: score each app
    final scored = visible
        .map((app) => (app: app, score: _score(app.searchKey, q)))
        .where((item) => item.score > 0)
        .toList();

    // Step 3: sort by score desc, then alphabetically for ties
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.app.searchKey.compareTo(b.app.searchKey);
    });

    return scored.take(limit).map((item) => item.app).toList();
  }

  static int _score(String appKey, String query) {
    if (appKey == query) return 100; // exact match
    if (appKey.startsWith(query)) return 80; // prefix match ("wh" → "whatsapp")
    // Word-boundary prefix: "ch" matches "Google Chrome" via word "chrome"
    final words = appKey.split(RegExp(r'[\s._\-]+'));
    if (words.any((w) => w.startsWith(query))) return 65;
    if (appKey.contains(query)) return 50; // substring ("tube" → "youtube")
    return 0;
  }
}
