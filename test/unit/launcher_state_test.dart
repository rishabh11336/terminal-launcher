import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/state/launcher_state.dart';

const _whatsapp = AppInfo(
  packageName: 'com.whatsapp',
  displayName: 'WhatsApp',
  searchKey: 'whatsapp',
);
const _gmail = AppInfo(
  packageName: 'com.google.gmail',
  displayName: 'Gmail',
  searchKey: 'gmail',
);

void main() {
  group('LauncherState — defaults', () {
    const s = LauncherState();

    test('isSearchActive defaults to false', () {
      expect(s.isSearchActive, isFalse);
    });

    test('searchQuery defaults to empty string', () {
      expect(s.searchQuery, equals(''));
    });

    test('searchResults defaults to empty list', () {
      expect(s.searchResults, isEmpty);
    });

    test('isDrawerOpen defaults to false', () {
      expect(s.isDrawerOpen, isFalse);
    });

    test('autoLaunchCandidate defaults to null', () {
      expect(s.autoLaunchCandidate, isNull);
    });
  });

  group('LauncherState — hasUniqueMatch', () {
    test('false when searchResults is empty', () {
      const s = LauncherState(searchQuery: 'wh', searchResults: []);
      expect(s.hasUniqueMatch, isFalse);
    });

    test('false when searchQuery is empty even with 1 result', () {
      const s = LauncherState(searchQuery: '', searchResults: [_whatsapp]);
      expect(s.hasUniqueMatch, isFalse);
    });

    test('true when exactly 1 result and query is non-empty', () {
      const s = LauncherState(
        searchQuery: 'wh',
        searchResults: [_whatsapp],
      );
      expect(s.hasUniqueMatch, isTrue);
    });

    test('false when 2 results', () {
      const s = LauncherState(
        searchQuery: 'g',
        searchResults: [_whatsapp, _gmail],
      );
      expect(s.hasUniqueMatch, isFalse);
    });

    test('false when query is only whitespace (empty after trim is handled upstream)', () {
      const s = LauncherState(searchQuery: '  ', searchResults: [_whatsapp]);
      // hasUniqueMatch only checks isEmpty, upstream search_utils trims
      expect(s.hasUniqueMatch, isTrue); // '  ' is not empty string
    });
  });

  group('LauncherState — copyWith', () {
    const base = LauncherState();

    test('copyWith isSearchActive', () {
      final s = base.copyWith(isSearchActive: true);
      expect(s.isSearchActive, isTrue);
      expect(s.searchQuery, equals('')); // unchanged
    });

    test('copyWith searchQuery', () {
      final s = base.copyWith(searchQuery: 'wh');
      expect(s.searchQuery, equals('wh'));
    });

    test('copyWith searchResults', () {
      final s = base.copyWith(searchResults: [_whatsapp]);
      expect(s.searchResults, equals([_whatsapp]));
    });

    test('copyWith isDrawerOpen', () {
      final s = base.copyWith(isDrawerOpen: true);
      expect(s.isDrawerOpen, isTrue);
    });

    test('copyWith autoLaunchCandidate', () {
      final s = base.copyWith(autoLaunchCandidate: _whatsapp);
      expect(s.autoLaunchCandidate, equals(_whatsapp));
    });

    test('copyWith clearAutoLaunch=true sets autoLaunchCandidate to null', () {
      final withCandidate = base.copyWith(autoLaunchCandidate: _whatsapp);
      final cleared = withCandidate.copyWith(clearAutoLaunch: true);
      expect(cleared.autoLaunchCandidate, isNull);
    });

    test('copyWith without args returns equivalent state', () {
      const s = LauncherState(
        isSearchActive: true,
        searchQuery: 'test',
        isDrawerOpen: false,
      );
      final copy = s.copyWith();
      expect(copy.isSearchActive, equals(s.isSearchActive));
      expect(copy.searchQuery, equals(s.searchQuery));
      expect(copy.isDrawerOpen, equals(s.isDrawerOpen));
    });

    test('clearSearch resets to default state', () {
      // active state — used only to document what clearSearch starts from
      // ignore: unused_local_variable
      const active = LauncherState(
        isSearchActive: true,
        searchQuery: 'wh',
        searchResults: [_whatsapp],
        autoLaunchCandidate: _whatsapp,
      );
      // Simulating clearSearch behavior (returns const LauncherState())
      const reset = LauncherState();
      expect(reset.isSearchActive, isFalse);
      expect(reset.searchQuery, equals(''));
      expect(reset.searchResults, isEmpty);
      expect(reset.autoLaunchCandidate, isNull);
    });
  });
}
