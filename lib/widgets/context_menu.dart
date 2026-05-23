import 'package:flutter/material.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';

/// Shows a text-only context menu for an app.
/// Dismisses on outside tap (modal bottom sheet behaviour).
void showAppContextMenu(
  BuildContext context,
  AppInfo app,
  LauncherNotifier notifier,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black,
    builder: (_) => ContextMenu(app: app, notifier: notifier),
  );
}

class ContextMenu extends StatelessWidget {
  final AppInfo app;
  final LauncherNotifier notifier;

  const ContextMenu({super.key, required this.app, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingH,
          vertical: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.displayName.toLowerCase(),
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.appNameFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _MenuOption(
              label: 'open',
              onTap: () {
                Navigator.pop(context);
                notifier.launchApp(app);
              },
            ),
            _MenuOption(
              label: 'pin',
              onTap: () {
                Navigator.pop(context);
                notifier.pinApp(app.packageName);
              },
            ),
            _MenuOption(
              label: 'hide',
              onTap: () {
                Navigator.pop(context);
                notifier.hideApp(app.packageName);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: AppSizes.appNameFontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
