import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/screens/app_drawer_screen.dart';
import 'package:terminal_launcher/screens/settings_screen.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/widgets/clock_widget.dart';
import 'package:terminal_launcher/widgets/context_menu.dart';
import 'package:terminal_launcher/widgets/pinned_apps_list.dart';
import 'package:terminal_launcher/widgets/search_overlay.dart';
import 'package:terminal_launcher/widgets/status_bar_widget.dart';
import 'package:terminal_launcher/widgets/terminal_cursor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  LauncherNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = context.read<LauncherNotifier>();
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_onNotifierChanged);
      _notifier = newNotifier;
      _notifier!.addListener(_onNotifierChanged);
    }
  }

  void _onNotifierChanged() {
    if (!(_notifier?.state.isSearchActive ?? true)) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onNotifierChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _activateSearch() {
    final notifier = context.read<LauncherNotifier>();
    if (notifier.state.isSearchActive) return;
    notifier.activateSearch();
    _focusNode.requestFocus();
  }

  void _deactivateSearch() {
    context.read<LauncherNotifier>().clearSearch();
    _controller.clear();
    _focusNode.unfocus();
  }

  void _onSwipeUp() {
    final notifier = context.read<LauncherNotifier>();
    if (notifier.state.isSearchActive) return;
    final animController = AnimationController(
      vsync: this,
      duration: AppDurations.drawerTransition,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      transitionAnimationController: animController,
      builder: (_) => const AppDrawerScreen(),
    ).whenComplete(() => animController.dispose());
  }

  void _onSwipeDown() {
    context.read<LauncherNotifier>().expandNotifications();
  }

  void _onDoubleTap() {
    if (_notifier?.lockOnDoubleTap ?? false) {
      context.read<LauncherNotifier>().lockScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back button while searching: clear search, don't exit launcher
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        final notifier = context.read<LauncherNotifier>();
        if (notifier.state.isSearchActive) {
          _deactivateSearch();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activateSearch,
          onDoubleTap: _onDoubleTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -AppSizes.swipeVelocityThreshold) {
              _onSwipeUp();
            } else if (details.primaryVelocity! >
                AppSizes.swipeVelocityThreshold) {
              _onSwipeDown();
            }
          },
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingH,
                AppSizes.paddingTop,
                AppSizes.paddingH,
                AppSizes.paddingBottom,
              ),
              child: Stack(
                children: [
                  // Always-mounted hidden TextField — TRD 7.4: avoids 100-200ms remount delay
                  Offstage(
                    offstage: true,
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      autofocus: false,
                      onChanged: (v) =>
                          context.read<LauncherNotifier>().onSearchChanged(v),
                    ),
                  ),
                  // Layer 1: main home screen content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status bar row (top-right, P2)
                      Consumer<LauncherNotifier>(
                        builder: (_, notifier, __) => Align(
                          alignment: Alignment.topRight,
                          child: Visibility(
                            visible: notifier.showStatusBar,
                            child: const StatusBarWidget(),
                          ),
                        ),
                      ),
                      const ClockWidget(),
                      const SizedBox(height: 48),
                      // Permission fallback — shown when no apps loaded
                      Consumer<LauncherNotifier>(
                        builder: (_, notifier, __) {
                          if (notifier.allVisibleApps.isEmpty &&
                              notifier.pinnedApps.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'grant package permission in settings to continue',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: AppSizes.hintFontSize,
                                  color: AppColors.textHint,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Only PinnedAppsList rebuilds when pinned apps change
                      Consumer<LauncherNotifier>(
                        builder: (ctx, notifier, __) => PinnedAppsList(
                          apps: notifier.pinnedApps,
                          onTap: notifier.launchApp,
                          onLongPress: (app) =>
                              showAppContextMenu(ctx, app, notifier),
                        ),
                      ),
                      const Spacer(),
                      const TerminalCursor(),
                    ],
                  ),
                  // Layer 2: search overlay — fades in when search is active
                  Positioned.fill(
                    child: Consumer<LauncherNotifier>(
                      builder: (_, notifier, __) => AnimatedOpacity(
                        opacity: notifier.state.isSearchActive ? 1.0 : 0.0,
                        duration: AppDurations.searchOverlayFade,
                        child: notifier.state.isSearchActive
                            ? Container(
                                color: Colors.black,
                                child: SearchOverlay(
                                  controller: _controller,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),        // Scaffold
    );          // PopScope
  }
}
