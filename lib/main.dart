import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/screens/home_screen.dart';
import 'package:terminal_launcher/services/app_cache_service.dart';
import 'package:terminal_launcher/services/app_launcher_service.dart';
import 'package:terminal_launcher/services/persistence_service.dart';
import 'package:terminal_launcher/services/platform_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only await prefs — fast SharedPreferences init
  final prefs = await PersistenceService.create();

  // Full-screen, no system chrome flicker
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // runApp immediately — UI renders at once, apps load in background via LauncherNotifier._init()
  runApp(TerminalLauncherApp(prefs: prefs));
}

class TerminalLauncherApp extends StatelessWidget {
  final PersistenceService prefs;

  const TerminalLauncherApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LauncherNotifier(
        cache: AppCacheService(),
        launcher: AppLauncherService(),
        platform: PlatformService(),
        prefs: prefs,
      ),
      child: MaterialApp(
        title: 'Terminal Launcher',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _NoTransitionBuilder(),
            },
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// Zero-animation page transitions — no slide/fade overhead (TRD Section 8 performance)
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
