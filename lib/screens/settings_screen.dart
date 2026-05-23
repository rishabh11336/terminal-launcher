import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/models/launcher_settings.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingH,
            AppSizes.paddingTop,
            AppSizes.paddingH,
            AppSizes.paddingBottom,
          ),
          child: Consumer<LauncherNotifier>(
            builder: (context, notifier, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(label: 'settings'),
                const SizedBox(height: 24),

                // Pinned apps
                const _SectionHeader(label: 'pinned apps'),
                _Divider(),
                if (notifier.pinnedApps.isEmpty)
                  const _HintText('none')
                else
                  ...notifier.pinnedApps.asMap().entries.map((e) {
                    final idx = e.key;
                    final app = e.value;
                    final order = notifier.pinnedApps
                        .map((a) => a.packageName)
                        .toList();
                    return _PinnedRow(
                      name: app.displayName.toLowerCase(),
                      canMoveUp: idx > 0,
                      canMoveDown: idx < notifier.pinnedApps.length - 1,
                      onMoveUp: () {
                        final newOrder = List<String>.from(order);
                        newOrder.insert(idx - 1, newOrder.removeAt(idx));
                        notifier.reorderPinned(newOrder);
                      },
                      onMoveDown: () {
                        final newOrder = List<String>.from(order);
                        newOrder.insert(idx + 1, newOrder.removeAt(idx));
                        notifier.reorderPinned(newOrder);
                      },
                      onRemove: () => notifier.unpinApp(app.packageName),
                    );
                  }),
                const SizedBox(height: 24),

                // Hidden apps
                const _SectionHeader(label: 'hidden apps'),
                _Divider(),
                if (notifier.hiddenApps.isEmpty)
                  const _HintText('none')
                else
                  ...notifier.hiddenApps.map((app) => _HiddenRow(
                        name: app.displayName.toLowerCase(),
                        onRestore: () => notifier.unhideApp(app.packageName),
                      )),
                const SizedBox(height: 24),

                // Appearance
                const _SectionHeader(label: 'appearance'),
                _Divider(),
                _SettingsRow(
                  label: 'accent color',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AccentColor.values.map((c) {
                      final selected = notifier.accentColor == c;
                      return GestureDetector(
                        onTap: () => notifier.setAccentColor(c),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: AppSizes.hintFontSize,
                              fontWeight: FontWeight.w400,
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                              decoration: selected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Behaviour
                const _SectionHeader(label: 'behaviour'),
                _Divider(),
                _ToggleRow(
                  label: 'battery + wifi',
                  value: notifier.showStatusBar,
                  onToggle: notifier.setShowStatusBar,
                ),
                _ToggleRow(
                  label: 'double-tap lock',
                  value: notifier.lockOnDoubleTap,
                  onToggle: notifier.setLockOnDoubleTap,
                ),
                const SizedBox(height: 40),

                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '< back',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: AppSizes.appNameFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
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

// --- Internal widgets ---

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: AppSizes.hintFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: AppColors.textHint, height: 1),
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;
  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: AppSizes.appNameFontSize,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _SettingsRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: AppSizes.appNameFontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onToggle;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      label: label,
      trailing: GestureDetector(
        onTap: () => onToggle(!value),
        child: Text(
          value ? 'on' : 'off',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: AppSizes.appNameFontSize,
            fontWeight: FontWeight.w400,
            color: value ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _PinnedRow extends StatelessWidget {
  final String name;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  const _PinnedRow({
    required this.name,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.appNameFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _IconBtn(
            label: '↑',
            onTap: canMoveUp ? onMoveUp : null,
          ),
          const SizedBox(width: 16),
          _IconBtn(
            label: '↓',
            onTap: canMoveDown ? onMoveDown : null,
          ),
          const SizedBox(width: 16),
          _IconBtn(label: '×', onTap: onRemove),
        ],
      ),
    );
  }
}

class _HiddenRow extends StatelessWidget {
  final String name;
  final VoidCallback onRestore;
  const _HiddenRow({required this.name, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.appNameFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRestore,
            child: const Text(
              'restore',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.hintFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _IconBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: AppSizes.appNameFontSize,
          fontWeight: FontWeight.w400,
          color: onTap != null ? AppColors.textPrimary : AppColors.textHint,
        ),
      ),
    );
  }
}
