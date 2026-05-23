import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/utils/search_utils.dart';
import 'package:terminal_launcher/widgets/app_list_tile.dart';
import 'package:terminal_launcher/widgets/context_menu.dart';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  List<AppInfo> _filteredApps = [];
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    // Auto-focus search bar when drawer opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build initial full list
    if (!_searchActive) {
      _filteredApps = context.read<LauncherNotifier>().allVisibleApps;
    }
  }

  void _onQueryChanged() {
    final notifier = context.read<LauncherNotifier>();
    final query = _controller.text;
    setState(() {
      _searchActive = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredApps = notifier.allVisibleApps;
      } else {
        _filteredApps = SearchUtils.filter(
          apps: notifier.allVisibleApps,
          query: query,
          hidden: notifier.hiddenPackages,
          limit: notifier.allVisibleApps.length, // no limit in drawer
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<LauncherNotifier>();

    return PopScope(
      // EC-06: home button while drawer open closes drawer, not launcher
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingH,
              AppSizes.paddingTop,
              AppSizes.paddingH,
              AppSizes.paddingBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invisible TextField for keyboard input
                Offstage(
                  offstage: true,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _controller,
                    autofocus: false,
                  ),
                ),
                // Visible query display
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Text(
                    '> ${_controller.text}',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: AppSizes.appNameFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // App list — rebuilds only on setState
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      return AppListTile(
                        app: app,
                        isHighlighted: false, // no auto-launch in drawer
                        onTap: () {
                          Navigator.pop(context);
                          notifier.launchApp(app);
                        },
                        onLongPress: () =>
                            showAppContextMenu(context, app, notifier),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
