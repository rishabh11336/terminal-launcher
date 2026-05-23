import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/widgets/app_list_tile.dart';
import 'package:terminal_launcher/widgets/context_menu.dart';

class SearchOverlay extends StatelessWidget {
  final TextEditingController controller;

  const SearchOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visible query display: "> " prefix + typed text
        _QueryDisplay(controller: controller),
        const SizedBox(height: 16),
        // Results — only this widget rebuilds on keystrokes
        Consumer<LauncherNotifier>(
          builder: (_, notifier, __) {
            final results = notifier.state.searchResults;
            final highlight = notifier.state.autoLaunchCandidate;
            if (results.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: results
                  .map((app) => AppListTile(
                        app: app,
                        isHighlighted: app == highlight,
                        onTap: () => notifier.launchApp(app),
                        onLongPress: () =>
                            showAppContextMenu(context, app, notifier),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QueryDisplay extends StatelessWidget {
  final TextEditingController controller;

  const _QueryDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) => Text(
        '> ${value.text}',
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: AppSizes.appNameFontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
