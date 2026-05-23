import 'package:flutter/material.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/utils/constants.dart';

class AppListTile extends StatelessWidget {
  final AppInfo app;
  final bool isHighlighted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AppListTile({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              app.displayName.toLowerCase(),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.appNameFontSize,
                fontWeight: FontWeight.w400,
                color: isHighlighted
                    ? AppColors.accentGreen
                    : AppColors.textPrimary,
              ),
            ),
            if (isHighlighted) ...[
              const SizedBox(width: 8),
              const Text(
                '↵',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: AppSizes.appNameFontSize,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
