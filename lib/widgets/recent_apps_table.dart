import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terminal_launcher/models/recent_app_info.dart';
import 'package:terminal_launcher/services/usage_stats_service.dart';
import 'package:terminal_launcher/state/launcher_notifier.dart';
import 'package:terminal_launcher/utils/constants.dart';

/// Unicode box-drawing table showing 3 most recently used apps.
/// Auto-refreshes every 60 seconds. Shows permission prompt if not granted.
class RecentAppsTable extends StatefulWidget {
  const RecentAppsTable({super.key});

  @override
  State<RecentAppsTable> createState() => _RecentAppsTableState();
}

class _RecentAppsTableState extends State<RecentAppsTable> {
  final _service = UsageStatsService();
  List<RecentAppInfo>? _apps;
  bool _permissionGranted = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final granted = await _service.isPermissionGranted();
      if (!granted) {
        if (mounted) setState(() { _permissionGranted = false; _apps = []; });
        return;
      }
      final apps = await _service.getRecentApps(count: 3);
      if (mounted) setState(() { _permissionGranted = true; _apps = apps; });
    } catch (_) {
      // silently fail — table stays in previous state
    }
  }

  String _relTime(int epochMs) {
    final diff = DateTime.now().millisecondsSinceEpoch - epochMs;
    final secs = diff ~/ 1000;
    if (secs < 60) return 'just now';
    final mins = secs ~/ 60;
    if (mins < 60) return '${mins}m ago';
    final hours = mins ~/ 60;
    if (hours < 24) return '${hours}h ago';
    return '${hours ~/ 24}d ago';
  }

  // Col widths: name=17 (│ + 15chars + │), time=10 (│ + 8chars + │), total=30
  static const _w1 = 15; // content width col1
  static const _w2 = 8;  // content width col2

  String _fmtName(String name) {
    final lower = name.toLowerCase();
    if (lower.length <= _w1) return lower.padRight(_w1);
    return '${lower.substring(0, _w1 - 1)}…';
  }

  String _fmtTime(String t) {
    if (t.length <= _w2) return t.padLeft(_w2);
    return t.substring(0, _w2);
  }


  static const _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: AppSizes.hintFontSize,
  );

  Widget _text(String s, {Color? color, bool tappable = false, VoidCallback? onTap}) {
    final t = Text(s, style: _base.copyWith(color: color ?? AppColors.textHint));
    if (tappable && onTap != null) {
      return GestureDetector(onTap: onTap, child: t);
    }
    return t;
  }

  // Colored data row: name=white, timestamp=dim
  Widget _appRow(String name, String time, {VoidCallback? onTap}) {
    final rich = RichText(
      text: TextSpan(
        style: _base,
        children: [
          TextSpan(text: '│ ', style: const TextStyle(color: AppColors.textHint)),
          TextSpan(text: _fmtName(name), style: const TextStyle(color: AppColors.textPrimary)),
          TextSpan(text: ' │ ', style: const TextStyle(color: AppColors.textHint)),
          TextSpan(text: _fmtTime(time), style: const TextStyle(color: AppColors.textHint)),
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
    const permRow = '│ grant usage access           │';

    final notifier = context.read<LauncherNotifier>();
    final apps = _apps;

    if (apps == null) {
      // Loading — show skeleton frame
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('recent', color: AppColors.labelRecent),
          _text(top),
          _text(bottom),
        ],
      );
    }

    if (!_permissionGranted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('recent', color: AppColors.labelRecent),
          _text(top),
          _text(
            permRow,
            tappable: true,
            onTap: () async {
              await _service.requestPermission();
              await Future.delayed(const Duration(seconds: 1));
              _load();
            },
          ),
          _text(bottom),
        ],
      );
    }

    if (apps.isEmpty) {
      const emptyRow = '│ no recent apps               │';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _text('recent', color: AppColors.labelRecent),
          _text(top),
          _text(emptyRow),
          _text(bottom),
        ],
      );
    }

    final rows = <Widget>[
      _text('recent', color: AppColors.labelRecent),
      _text(top),
    ];
    for (var i = 0; i < apps.length; i++) {
      final app = apps[i];
      rows.add(_appRow(
        app.appName,
        _relTime(app.lastUsed),
        onTap: () => notifier.launchByPackage(app.packageName),
      ));
      if (i < apps.length - 1) rows.add(_text(mid));
    }
    rows.add(_text(bottom));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
