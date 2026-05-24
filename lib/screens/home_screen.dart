import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/screens/app_drawer_screen.dart';
import 'package:terminal_launcher/screens/settings_screen.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/widgets/clock_widget.dart';
import 'package:terminal_launcher/widgets/context_menu.dart';
import 'package:terminal_launcher/widgets/pinned_apps_list.dart';
import 'package:terminal_launcher/widgets/search_overlay.dart';
import 'package:terminal_launcher/widgets/status_bar_widget.dart';
import 'package:terminal_launcher/services/system_metrics_service.dart';
import 'package:terminal_launcher/widgets/notifications_table.dart';
import 'package:terminal_launcher/widgets/system_metrics_table.dart';
import 'package:terminal_launcher/widgets/recent_apps_table.dart';
import 'package:terminal_launcher/widgets/terminal_cursor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  LauncherNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Focus listener handles back-button IME dismissal
    _focusNode.addListener(_onFocusChanged);
  }

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

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && (_notifier?.state.isSearchActive ?? false)) {
      _deactivateSearch();
    }
  }

  void _onNotifierChanged() {
    if (!(_notifier?.state.isSearchActive ?? true)) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  // Detects swipe-down keyboard dismissal (doesn't remove focus, only lowers IME)
  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
            .instance.platformDispatcher.implicitView?.viewInsets.bottom ??
        0.0;
    if (bottomInset == 0.0 && (_notifier?.state.isSearchActive ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deactivateSearch();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifier?.removeListener(_onNotifierChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    SystemMetricsService().dispose();
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
        body: Stack(
          children: [
            // Double-tap layer — sits behind content, translucent so content
            // still receives taps. Separate recognizer avoids the 300ms onTap
            // delay Flutter adds when onDoubleTap is on the same detector.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _onDoubleTap,
              ),
            ),
            GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activateSearch,
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
                      // Status bar row — rebuilds only when showStatusBar changes
                      Align(
                        alignment: Alignment.topRight,
                        child: Builder(
                          builder: (ctx) {
                            final show = ctx.select<LauncherNotifier, bool>(
                              (n) => n.showStatusBar,
                            );
                            return Visibility(
                              visible: show,
                              child: const StatusBarWidget(),
                            );
                          },
                        ),
                      ),
                      const ClockWidget(),
                      const SizedBox(height: 24),
                      // SystemMetricsTable — rebuilds only when showSystemMetrics changes
                      Builder(
                        builder: (ctx) {
                          final show = ctx.select<LauncherNotifier, bool>(
                            (n) => n.showSystemMetrics,
                          );
                          return Visibility(
                            visible: show,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SystemMetricsTable(),
                                SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                      const RecentAppsTable(),
                      const SizedBox(height: 24),
                      const NotificationsTable(),
                      const SizedBox(height: 24),
                      // Permission fallback — rebuilds only when app-list emptiness changes
                      Builder(
                        builder: (ctx) {
                          final isEmpty = ctx.select<LauncherNotifier, bool>(
                            (n) => n.allVisibleApps.isEmpty && n.pinnedApps.isEmpty,
                          );
                          if (!isEmpty) return const SizedBox.shrink();
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
                        },
                      ),
                      // PinnedAppsList — rebuilds only when pins, showIcons, or notif counts change
                      Selector<LauncherNotifier,
                          ({List<AppInfo> apps, bool showIcons, Map<String, int> counts})>(
                        selector: (_, n) => (
                          apps: n.pinnedApps,
                          showIcons: n.showIcons,
                          counts: n.notifCounts,
                        ),
                        builder: (ctx, data, __) {
                          final notifier = ctx.read<LauncherNotifier>();
                          return PinnedAppsList(
                            apps: data.apps,
                            showIcons: data.showIcons,
                            notifCount: (pkg) => data.counts[pkg] ?? 0,
                            onTap: notifier.launchApp,
                            onLongPress: (app) =>
                                showAppContextMenu(ctx, app, notifier),
                          );
                        },
                      ),
                      const Spacer(),
                      const TerminalCursor(),
                    ],
                  ),
                  // Layer 2: search overlay — rebuilds only when isSearchActive changes
                  Positioned.fill(
                    child: Builder(
                      builder: (ctx) {
                        final active = ctx.select<LauncherNotifier, bool>(
                          (n) => n.state.isSearchActive,
                        );
                        return AnimatedOpacity(
                          opacity: active ? 1.0 : 0.0,
                          duration: AppDurations.searchOverlayFade,
                          child: active
                              ? Container(
                                  color: Colors.black,
                                  child: SearchOverlay(controller: _controller),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),          // inner GestureDetector
          ],        // outer Stack children
        ),          // outer Stack (body:)
      ),        // Scaffold
    );          // PopScope
  }
}
