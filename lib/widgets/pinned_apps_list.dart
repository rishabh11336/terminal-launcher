import 'package:flutter/material.dart';
import 'package:terminal_launcher/models/app_info.dart';
import 'package:terminal_launcher/utils/constants.dart';
import 'package:terminal_launcher/widgets/app_icon_widget.dart';

class PinnedAppsList extends StatelessWidget {
  final List<AppInfo> apps;
  final bool showIcons;
  final int Function(String packageName) notifCount;
  final void Function(AppInfo app) onTap;
  final void Function(AppInfo app) onLongPress;

  const PinnedAppsList({
    super.key,
    required this.apps,
    required this.onTap,
    required this.onLongPress,
    this.showIcons = true,
    this.notifCount = _zeroCount,
  });

  static int _zeroCount(String _) => 0;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Text(
        'long press any app to pin it',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: AppSizes.hintFontSize,
          color: AppColors.textHint,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    // Max 5 pinned apps rendered (TRD AppSizes.maxPinnedApps)
    final visible = apps.take(AppSizes.maxPinnedApps).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(visible[i]),
            onLongPress: () => onLongPress(visible[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (showIcons) ...[
                    AppIconWidget(
                      packageName: visible[i].packageName,
                      notifCount: notifCount(visible[i].packageName),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    visible[i].displayName.toLowerCase(),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: AppSizes.appNameFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Text badge when icons hidden and notifications pending
                  if (!showIcons) Builder(builder: (_) {
                    final count = notifCount(visible[i].packageName);
                    if (count <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '[$count]',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: AppSizes.hintFontSize,
                          fontWeight: FontWeight.w400,
                          color: count >= 5
                              ? AppColors.metricDanger
                              : AppColors.metricWarn,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
