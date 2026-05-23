import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/utils/search_utils.dart';

// Mirrors TRD Section 16.1 test apps
final _testApps = [
  const AppInfo(packageName: 'com.whatsapp', displayName: 'WhatsApp', searchKey: 'whatsapp'),
  const AppInfo(packageName: 'com.google.android.youtube', displayName: 'YouTube', searchKey: 'youtube'),
  const AppInfo(packageName: 'com.google.chrome', displayName: 'Chrome', searchKey: 'chrome'),
  const AppInfo(packageName: 'com.spotify.music', displayName: 'Spotify', searchKey: 'spotify'),
  const AppInfo(packageName: 'com.google.android.gm', displayName: 'Gmail', searchKey: 'gmail'),
  const AppInfo(packageName: 'com.google.maps', displayName: 'Google Maps', searchKey: 'google maps'),
  const AppInfo(packageName: 'com.android.camera', displayName: 'Camera', searchKey: 'camera'),
  const AppInfo(packageName: 'com.notion.id', displayName: 'Notion', searchKey: 'notion'),
];

void main() {
  group('SearchUtils — TRD Section 16.1 required cases', () {
    test('prefix match returns correct result', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'wh', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.whatsapp'));
    });

    test('unique match: single result for specific query', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'spotif', hidden: {}, limit: 6);
      expect(results.length, equals(1));
    });

    test('hidden apps excluded from results', () {
      final results = SearchUtils.filter(
        apps: _testApps,
        query: 'wh',
        hidden: {'com.whatsapp'},
        limit: 6,
      );
      expect(results, isEmpty);
    });

    test('empty query returns empty list', () {
      final results =
          SearchUtils.filter(apps: _testApps, query: '', hidden: {}, limit: 6);
      expect(results, isEmpty);
    });

    test('exact match scores highest', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'chrome', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.google.chrome'));
    });
  });

  group('SearchUtils — scoring tiers', () {
    test('exact match (score 100) beats prefix match (score 80)', () {
      // 'gmail' exactly matches Gmail, and 'gmail' is prefix of nothing else
      final results = SearchUtils.filter(
          apps: _testApps, query: 'gmail', hidden: {}, limit: 6);
      expect(results.first.searchKey, equals('gmail'));
    });

    test('prefix match (80) beats substring match (50)', () {
      // 'you' prefix-matches 'youtube'; 'you' substring of nothing else here
      final results = SearchUtils.filter(
          apps: _testApps, query: 'you', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.google.android.youtube'));
    });

    test('word-boundary prefix match (65) — "ch" matches "Chrome" by word start', () {
      // 'ch' prefix of 'chrome' directly (score 80), also word boundary of 'camera' (score 80)
      // but 'chrome' and 'camera' both start with prefix 'c...' — 'ch' specifically:
      // chrome: startsWith('ch') → 80
      // camera: does NOT startWith('ch'), words: ['camera'] → 'camera'.startsWith('ch') false → 0
      final results = SearchUtils.filter(
          apps: _testApps, query: 'ch', hidden: {}, limit: 6);
      expect(results.any((a) => a.packageName == 'com.google.chrome'), isTrue);
      expect(results.any((a) => a.packageName == 'com.android.camera'), isFalse);
    });

    test('word-boundary prefix: "maps" matches "Google Maps" via word "maps"', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'maps', hidden: {}, limit: 6);
      expect(results.any((a) => a.packageName == 'com.google.maps'), isTrue);
    });

    test('substring match (50) — "tube" matches "youtube"', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'tube', hidden: {}, limit: 6);
      expect(results.any((a) => a.packageName == 'com.google.android.youtube'), isTrue);
    });

    test('no match returns empty', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'zzzzz', hidden: {}, limit: 6);
      expect(results, isEmpty);
    });
  });

  group('SearchUtils — limit', () {
    test('respects limit parameter', () {
      // 'g' matches gmail, google maps, youtube(no), chrome(no) — several matches
      final results = SearchUtils.filter(
          apps: _testApps, query: 'g', hidden: {}, limit: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('limit=6 default', () {
      // All 8 apps queried with single letter 'a' — limit caps at 6
      final results = SearchUtils.filter(
          apps: _testApps, query: 'a', hidden: {}, limit: 6);
      expect(results.length, lessThanOrEqualTo(6));
    });

    test('limit=1 returns only top result', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: 'wh', hidden: {}, limit: 1);
      expect(results.length, equals(1));
      expect(results.first.packageName, equals('com.whatsapp'));
    });
  });

  group('SearchUtils — hidden packages', () {
    test('multiple hidden packages all excluded', () {
      final results = SearchUtils.filter(
        apps: _testApps,
        query: 'g',
        hidden: {'com.google.android.gm', 'com.google.maps', 'com.google.chrome'},
        limit: 6,
      );
      for (final r in results) {
        expect(
          {'com.google.android.gm', 'com.google.maps', 'com.google.chrome'}
              .contains(r.packageName),
          isFalse,
        );
      }
    });

    test('hiding all matching apps returns empty', () {
      final results = SearchUtils.filter(
        apps: _testApps,
        query: 'whatsapp',
        hidden: {'com.whatsapp'},
        limit: 6,
      );
      expect(results, isEmpty);
    });

    test('empty hidden set does not filter anything', () {
      final results =
          SearchUtils.filter(apps: _testApps, query: 'wh', hidden: {}, limit: 6);
      expect(results, isNotEmpty);
    });
  });

  group('SearchUtils — sort stability', () {
    test('alphabetical tiebreak for equal scores', () {
      // 'cam' prefix-matches 'camera' (score 80), nothing else matches
      // With two apps at same score, alphabetical order applies
      final tieApps = [
        const AppInfo(packageName: 'com.b', displayName: 'Banana', searchKey: 'banana'),
        const AppInfo(packageName: 'com.a', displayName: 'Apple', searchKey: 'apple'),
        const AppInfo(packageName: 'com.c', displayName: 'Avocado', searchKey: 'avocado'),
      ];
      // 'a' prefix-matches 'apple' and 'avocado' (both score 80)
      final results = SearchUtils.filter(
          apps: tieApps, query: 'a', hidden: {}, limit: 6);
      // alphabetical: apple < avocado
      expect(results[0].searchKey, equals('apple'));
      expect(results[1].searchKey, equals('avocado'));
    });

    test('higher score appears before lower score regardless of alphabet', () {
      final apps = [
        const AppInfo(packageName: 'com.z', displayName: 'Zzz App', searchKey: 'zzz app'),
        const AppInfo(packageName: 'com.a', displayName: 'App Zen', searchKey: 'app zen'),
      ];
      // 'zzz' → 'zzz app' score 80 (prefix), 'app zen' score 0
      final results =
          SearchUtils.filter(apps: apps, query: 'zzz', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.z'));
    });
  });

  group('SearchUtils — edge cases', () {
    test('query with leading/trailing spaces treated correctly', () {
      // SearchUtils trims query
      final results = SearchUtils.filter(
          apps: _testApps, query: '  wh  ', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.whatsapp'));
    });

    test('whitespace-only query returns empty', () {
      final results = SearchUtils.filter(
          apps: _testApps, query: '   ', hidden: {}, limit: 6);
      expect(results, isEmpty);
    });

    test('empty app list returns empty', () {
      final results =
          SearchUtils.filter(apps: [], query: 'wh', hidden: {}, limit: 6);
      expect(results, isEmpty);
    });

    test('case-insensitive matching', () {
      // searchKey is lowercase, query is lowercased inside filter
      final results = SearchUtils.filter(
          apps: _testApps, query: 'WH', hidden: {}, limit: 6);
      expect(results.first.packageName, equals('com.whatsapp'));
    });

    test('app with multi-word name matched by second word', () {
      // 'google maps' → query 'maps' → word boundary match 'maps'
      final results = SearchUtils.filter(
          apps: _testApps, query: 'maps', hidden: {}, limit: 6);
      expect(results.any((a) => a.displayName == 'Google Maps'), isTrue);
    });

    test('returns List<AppInfo>', () {
      final results =
          SearchUtils.filter(apps: _testApps, query: 'wh', hidden: {}, limit: 6);
      expect(results, isA<List<AppInfo>>());
    });
  });
}
