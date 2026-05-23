// Phase 1 + Phase 3 widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terminal_launcher/main.dart';
import 'package:terminal_launcher/screens/home_screen.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';
import 'package:terminal_launcher/services/app_launcher_service.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/services/platform_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/widgets/clock_widget.dart';
import 'package:terminal_launcher/widgets/terminal_cursor.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/widgets/pinned_apps_list.dart';

// Helper: build TerminalLauncherApp with mocked prefs
Future<Widget> _buildApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PersistenceService.create();
  return TerminalLauncherApp(prefs: prefs);
}

// Helper: build HomeScreen with a LauncherNotifier provider (no device needed)
Future<Widget> _buildHomeScreen() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await PersistenceService.create();
  return ChangeNotifierProvider(
    create: (_) => LauncherNotifier(
      cache: AppCacheService(),
      launcher: AppLauncherService(),
      platform: PlatformService(),
      prefs: prefs,
    ),
    child: const MaterialApp(
      home: HomeScreen(),
    ),
  );
}

void main() {
  group('TerminalLauncherApp — structure', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(await _buildApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('debug banner is disabled', (tester) async {
      await tester.pumpWidget(await _buildApp());
      final apps = tester.widgetList<MaterialApp>(find.byType(MaterialApp));
      for (final app in apps) {
        expect(app.debugShowCheckedModeBanner, isFalse);
      }
    });

    testWidgets('theme brightness is dark', (tester) async {
      await tester.pumpWidget(await _buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.theme?.brightness, equals(Brightness.dark));
    });

    testWidgets('theme scaffoldBackgroundColor is black', (tester) async {
      await tester.pumpWidget(await _buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.theme?.scaffoldBackgroundColor, equals(Colors.black));
    });

    testWidgets('title is Terminal Launcher', (tester) async {
      await tester.pumpWidget(await _buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
      expect(app.title, equals('Terminal Launcher'));
    });
  });

  group('HomeScreen — widget tree', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump(); // settle animations
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows ClockWidget', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.byType(ClockWidget), findsOneWidget);
    });

    testWidgets('shows TerminalCursor', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.byType(TerminalCursor), findsOneWidget);
    });

    testWidgets('shows PinnedAppsList', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.byType(PinnedAppsList), findsOneWidget);
    });

    testWidgets('shows empty pinned apps hint text', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.text('long press any app to pin it'), findsOneWidget);
    });

    testWidgets('scaffold background is black', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      final homeScaffold = scaffolds.first;
      expect(homeScaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('search overlay not visible initially', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      // AnimatedOpacity at 0.0 means search is inactive
      final opacities = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacities.any((o) => o.opacity == 0.0), isTrue);
    });

    testWidgets('cursor shows > text', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.text('> '), findsOneWidget);
    });

    testWidgets('cursor shows _ text', (tester) async {
      await tester.pumpWidget(await _buildHomeScreen());
      await tester.pump();
      expect(find.text('_'), findsOneWidget);
    });
  });

  group('HomeScreen — search activation', () {
    testWidgets('tap activates search — notifier state changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PersistenceService.create();
      late LauncherNotifier notifier;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) {
            notifier = LauncherNotifier(
              cache: AppCacheService(),
              launcher: AppLauncherService(),
              platform: PlatformService(),
              prefs: prefs,
            );
            return notifier;
          },
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(notifier.state.isSearchActive, isFalse);

      // onTap fires after ~300ms delay when onDoubleTap is also set (Flutter disambiguation)
      await tester.tapAt(const Offset(200, 400));
      await tester.pump(const Duration(milliseconds: 500));

      expect(notifier.state.isSearchActive, isTrue);
    });

    testWidgets('search overlay AnimatedOpacity reaches 1.0 when active', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PersistenceService.create();
      late LauncherNotifier notifier;

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) {
            notifier = LauncherNotifier(
              cache: AppCacheService(),
              launcher: AppLauncherService(),
              platform: PlatformService(),
              prefs: prefs,
            );
            return notifier;
          },
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      // Directly activate search via notifier
      notifier.activateSearch();
      await tester.pump(); // rebuild Consumer
      await tester.pump(const Duration(milliseconds: 200)); // complete fade animation

      final opacities = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacities.any((o) => o.opacity == 1.0), isTrue);
    });
  });

  group('ClockWidget', () {
    testWidgets('renders time string', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ClockWidget()),
      ));
      await tester.pump();
      // Time format HH:mm — find a text matching pattern
      final texts = tester.widgetList<Text>(find.byType(Text));
      final timeText = texts.firstWhere(
        (t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t.data ?? ''),
        orElse: () => const Text(''),
      );
      expect(timeText.data, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    testWidgets('renders date string', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ClockWidget()),
      ));
      await tester.pump();
      // Date format: "Monday, 23 May" — find non-empty text with comma
      final texts = tester.widgetList<Text>(find.byType(Text));
      final dateText = texts.firstWhere(
        (t) => (t.data ?? '').contains(','),
        orElse: () => const Text(''),
      );
      expect(dateText.data, isNotEmpty);
      expect(dateText.data, contains(','));
    });

    testWidgets('time text uses JetBrainsMono font', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ClockWidget()),
      ));
      await tester.pump();
      final texts = tester.widgetList<Text>(find.byType(Text));
      final timeText = texts.firstWhere(
        (t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t.data ?? ''),
        orElse: () => const Text(''),
      );
      expect(timeText.style?.fontFamily, equals('JetBrainsMono'));
    });

    testWidgets('time text font size is 48', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ClockWidget()),
      ));
      await tester.pump();
      final texts = tester.widgetList<Text>(find.byType(Text));
      final timeText = texts.firstWhere(
        (t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t.data ?? ''),
        orElse: () => const Text(''),
      );
      expect(timeText.style?.fontSize, equals(48));
    });
  });

  group('TerminalCursor', () {
    testWidgets('renders > and _ characters', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TerminalCursor()),
      ));
      await tester.pump();
      expect(find.text('> '), findsOneWidget);
      expect(find.text('_'), findsOneWidget);
    });

    testWidgets('uses FadeTransition for blink', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TerminalCursor()),
      ));
      await tester.pump();
      // FadeTransition is inside TerminalCursor — find descendant specifically
      expect(
        find.descendant(
          of: find.byType(TerminalCursor),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cursor _ text uses JetBrainsMono', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TerminalCursor()),
      ));
      await tester.pump();
      final underscore = tester.widget<Text>(find.text('_'));
      expect(underscore.style?.fontFamily, equals('JetBrainsMono'));
    });
  });

  group('PinnedAppsList', () {
    testWidgets('shows hint when no apps', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PinnedAppsList(
            apps: const [],
            onTap: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ));
      expect(find.text('long press any app to pin it'), findsOneWidget);
    });

    testWidgets('shows app names when apps provided', (tester) async {
      const apps = [
        AppInfo(packageName: 'com.whatsapp', displayName: 'WhatsApp', searchKey: 'whatsapp'),
        AppInfo(packageName: 'com.google.gmail', displayName: 'Gmail', searchKey: 'gmail'),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PinnedAppsList(
            apps: apps,
            onTap: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ));
      // displayName.toLowerCase()
      expect(find.text('whatsapp'), findsOneWidget);
      expect(find.text('gmail'), findsOneWidget);
    });

    testWidgets('renders max 5 apps when more provided', (tester) async {
      final apps = List.generate(
        8,
        (i) => AppInfo(
          packageName: 'com.app.$i',
          displayName: 'App $i',
          searchKey: 'app $i',
        ),
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PinnedAppsList(
            apps: apps,
            onTap: (_) {},
            onLongPress: (_) {},
          ),
        ),
      ));
      // Only 5 GestureDetectors rendered
      expect(find.byType(GestureDetector).evaluate().length,
          lessThanOrEqualTo(5));
    });

    testWidgets('onTap callback fires', (tester) async {
      AppInfo? tapped;
      const app = AppInfo(
          packageName: 'com.test', displayName: 'Test', searchKey: 'test');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PinnedAppsList(
            apps: const [app],
            onTap: (a) => tapped = a,
            onLongPress: (_) {},
          ),
        ),
      ));
      await tester.tap(find.text('test'));
      expect(tapped, equals(app));
    });
  });

  group('NoTransitionBuilder', () {
    testWidgets('no SlideTransition on home route', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();
      // NoTransitionBuilder prevents route-level SlideTransition (the default Android transition)
      expect(find.byType(SlideTransition), findsNothing);
    });
  });
}
