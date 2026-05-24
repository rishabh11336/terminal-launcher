import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/services/notification_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';

/// Unicode box-drawing table showing apps with active notification counts.
/// Listens to NotificationService.countStream. Hidden when no active notifications.
/// Shows permission prompt row when notification access not granted.
class NotificationsTable extends StatefulWidget {
  const NotificationsTable({super.key});

  @override
  State<NotificationsTable> createState() => _NotificationsTableState();
}

class _NotificationsTableState extends State<NotificationsTable> {
  final _service = NotificationService();
  bool? _permissionGranted; // null = not yet checked
  Map<String, int> _counts = {};
  StreamSubscription<Map<String, int>>? _sub;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _sub = _service.countStream.listen((counts) {
      if (mounted) setState(() => _counts = counts);
    });
  }

  Future<void> _checkPermission() async {
    final granted = await _service.isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static const _w1 = 15; // content width col1
  static const _w2 = 8;  // content width col2

  String _fmtName(String name) {
    final lower = name.toLowerCase();
    if (lower.length <= _w1) return lower.padRight(_w1);
    return '${lower.substring(0, _w1 - 1)}…';
  }

  String _fmtCount(int count) {
    final s = count >= 100 ? '99+' : count.toString();
    return s.padLeft(_w2);
  }


  static const _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: AppSizes.hintFontSize,
  );

  Color _countColor(int count) =>
      count >= 5 ? AppColors.metricDanger : AppColors.metricWarn;

  Widget _text(String s, {Color? color, VoidCallback? onTap}) {
    final t = Text(s, style: _base.copyWith(color: color ?? AppColors.textHint));
    if (onTap != null) return GestureDetector(onTap: onTap, child: t);
    return t;
  }

  // Colored notif row: name=white, count=red(≥5)/amber(1-4)
  Widget _notifRow(String name, int count, {VoidCallback? onTap}) {
    final rich = RichText(
      text: TextSpan(
        style: _base,
        children: [
          TextSpan(text: '│ ', style: const TextStyle(color: AppColors.textHint)),
          TextSpan(text: _fmtName(name), style: const TextStyle(color: AppColors.textPrimary)),
          TextSpan(text: ' │ ', style: const TextStyle(color: AppColors.textHint)),
          TextSpan(text: _fmtCount(count), style: TextStyle(color: _countColor(count))),
          TextSpan(text: ' │', style: const TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: rich);
    return rich;
  }

  @override
  Widget build(BuildContext context) {
    const top    = '┌─────────────────┬──────────┐';
    const mid    = '├─────────────────┼──────────┤';
    const bottom = '└─────────────────┴──────────┘';

    // Still checking permission — show skeleton
    if (_permissionGranted == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('notifications', color: AppColors.labelNotif),
          _text(top),
          _text(bottom),
        ],
      );
    }

    // Permission not granted — show tap-to-grant prompt
    if (!_permissionGranted!) {
      const permRow = '│ grant notif access           │';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('notifications', color: AppColors.labelNotif),
          _text(top),
          _text(
            permRow,
            onTap: () async {
              await _service.requestPermission();
              await Future.delayed(const Duration(seconds: 1));
              _checkPermission();
            },
          ),
          _text(bottom),
        ],
      );
    }

    final notifier = context.read<LauncherNotifier>();
    final watched = context.select<LauncherNotifier, Set<String>>(
      (n) => n.watchedNotifPackages,
    );

    // Filter to apps with count > 0, sort by count desc
    var active = _counts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // If watched list non-empty, restrict to those packages only
    if (watched.isNotEmpty) {
      active = active.where((e) => watched.contains(e.key)).toList();
    }

    final top3 = active.take(3).toList();

    // No active notifications — show quiet state
    if (top3.isEmpty) {
      const quietRow = '│ no notifications             │';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('notifications', color: AppColors.labelNotif),
          _text(top),
          _text(quietRow),
          _text(bottom),
        ],
      );
    }

    final rows = <Widget>[
      _text('notifications', color: AppColors.labelNotif),
      _text(top),
    ];
    for (var i = 0; i < top3.length; i++) {
      final e = top3[i];
      final displayName = notifier.displayNameForPackage(e.key);
      rows.add(_notifRow(
        displayName,
        e.value,
        onTap: () => notifier.launchByPackage(e.key),
      ));
      if (i < top3.length - 1) rows.add(_text(mid));
    }
    rows.add(_text(bottom));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
