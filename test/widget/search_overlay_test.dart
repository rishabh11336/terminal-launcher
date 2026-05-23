import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';
import 'package:terminal_launcher/services/app_launcher_service.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/services/platform_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/widgets/search_overlay.dart';
import 'package:terminal_launcher/widgets/app_list_tile.dart';

Future<LauncherNotifier> _makeNotifier() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PersistenceService.create();
  final cache = AppCacheService();
  cache.updatePinnedOrder([]);
  cache.updateHiddenPackages({});
  return LauncherNotifier(
    cache: cache,
    launcher: AppLauncherService(),
    platform: PlatformService(),
    prefs: prefs,
  );
}

class _Harness extends StatefulWidget {
  final LauncherNotifier notifier;
  const _Harness({required this.notifier});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LauncherNotifier>.value(
      value: widget.notifier,
      child: MaterialApp(
        home: Scaffold(
          body: SearchOverlay(
            controller: _controller,
          ),
        ),
      ),
    );
  }
}

void main() {
  group('SearchOverlay — structure', () {
    testWidgets('renders without crashing', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();
      expect(find.byType(SearchOverlay), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('contains Offstage widget (hidden TextField)', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();
      expect(find.byType(Offstage), findsWidgets);
      notifier.dispose();
    });

    testWidgets('no AppListTile shown when results empty', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();
      expect(find.byType(AppListTile), findsNothing);
      notifier.dispose();
    });

    testWidgets('shows > prompt character', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();
      expect(find.textContaining('>'), findsWidgets);
      notifier.dispose();
    });

    testWidgets('query display uses JetBrainsMono', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();
      final promptText = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.data ?? '').startsWith('>'),
              orElse: () => const Text(''));
      expect(promptText.style?.fontFamily, equals('JetBrainsMono'));
      notifier.dispose();
    });
  });

  group('SearchOverlay — search active state', () {
    testWidgets('activating search does not crash overlay', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();

      notifier.activateSearch();
      await tester.pump();

      expect(find.byType(SearchOverlay), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('no results shown when search results empty', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));

      notifier.activateSearch();
      await tester.pump();

      expect(find.byType(AppListTile), findsNothing);
      notifier.dispose();
    });
  });

  group('SearchOverlay — Consumer rebuilds', () {
    testWidgets('rebuilds without error on notifier change', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();

      notifier.activateSearch();
      await tester.pump();
      notifier.clearSearch();
      await tester.pump();

      expect(find.byType(SearchOverlay), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('dispose does not throw after widget removed', (tester) async {
      final notifier = await _makeNotifier();
      await tester.pumpWidget(_Harness(notifier: notifier));
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(() => notifier.dispose(), returnsNormally);
    });
  });
}
