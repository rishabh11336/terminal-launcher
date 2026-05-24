import 'package:flutter/material.dart';
import 'package:terminal_launcher/models/system_metrics.dart';
import 'package:terminal_launcher/services/system_metrics_service.dart';
import 'package:terminal_launcher/utils/constants.dart';

/// Unicode box-drawing table showing live system metrics with IDE-style colors.
/// Polls every 2 seconds via SystemMetricsService.stream.
/// Uses StreamBuilder — only this widget rebuilds on each poll.
class SystemMetricsTable extends StatelessWidget {
  const SystemMetricsTable({super.key});

  static const _top    = '┌───────────┬──────────────────────┐';
  static const _mid    = '├───────────┼──────────────────────┤';
  static const _bottom = '└───────────┴──────────────────────┘';

  static const _base = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: AppSizes.hintFontSize,
  );

  // ── color thresholds ──────────────────────────────────────────────────────

  Color _cpuColor(int pct) =>
      pct >= 60 ? AppColors.metricDanger : pct >= 30 ? AppColors.metricWarn : AppColors.metricGood;

  Color _ramColor(int pct) =>
      pct >= 80 ? AppColors.metricDanger : pct >= 60 ? AppColors.metricWarn : AppColors.metricGood;

  Color _battColor(int pct, bool charging) {
    if (charging) return AppColors.metricCharging;
    if (pct < 20)  return AppColors.metricDanger;
    if (pct < 50)  return AppColors.metricWarn;
    return AppColors.metricGood;
  }

  Color _storageColor(int pct) =>
      pct >= 90 ? AppColors.metricDanger : pct >= 70 ? AppColors.metricWarn : AppColors.metricGood;

  Color _tempColor(int c) =>
      c >= 45 ? AppColors.metricDanger : c >= 40 ? AppColors.metricWarn : c >= 35 ? AppColors.metricGood : AppColors.metricCold;

  Color _netColor(int bps) => bps > 0 ? AppColors.metricInfo : AppColors.textHint;

  Color _wifiColor(int rssi) {
    if (rssi == 0)    return AppColors.textHint;
    if (rssi >= -50)  return AppColors.metricGood;
    if (rssi >= -70)  return AppColors.metricInfo;
    if (rssi >= -80)  return AppColors.metricWarn;
    return AppColors.metricDanger;
  }

  // ── formatters ────────────────────────────────────────────────────────────

  String _buildBar(int pct) {
    final filled = (pct / 10).round().clamp(0, 10);
    return '${'▓' * filled}${'░' * (10 - filled)}';
  }

  String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '< 1 KB/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  // ── cell builders ─────────────────────────────────────────────────────────

  String _c1(String label) => ' ${label.padRight(9)} '; // 11 chars

  String _c2Bar(int pct, {String suffix = ''}) {
    final bar    = _buildBar(pct);
    final pctStr = suffix.isNotEmpty ? '$pct% $suffix' : '$pct%';
    return ' $bar  ${pctStr.padLeft(8)} '; // 22 chars
  }

  String _c2Speed(String speed) => ' ${speed.padRight(20)} '; // 22 chars

  String _c2Temp(int tempC)    => ' ${'${tempC}°C'.padRight(20)} '; // 22 chars

  String _c2Loading()          => ' ${'...'.padRight(20)} ';

  String _c2Rssi(int rssi) {
    final label = rssi == 0 ? 'no signal' : '$rssi dBm';
    return ' ${label.padRight(20)} ';
  }

  // ── row widgets ───────────────────────────────────────────────────────────

  Widget _structRow(String s) =>
      Text(s, style: _base.copyWith(color: AppColors.textHint));

  Widget _loadingRow(String label) => RichText(
        text: TextSpan(
          style: _base,
          children: [
            TextSpan(text: '│${_c1(label)}│${_c2Loading()}│',
                style: const TextStyle(color: AppColors.textHint)),
          ],
        ),
      );

  Widget _colorRow(String label, String col2, Color valueColor) => RichText(
        text: TextSpan(
          style: _base,
          children: [
            TextSpan(
              text: '│${_c1(label)}│',
              style: const TextStyle(color: AppColors.textHint),
            ),
            TextSpan(text: col2, style: TextStyle(color: valueColor)),
            const TextSpan(text: '│', style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      );

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemMetrics>(
      stream: SystemMetricsService().stream, // singleton factory — const not applicable
      builder: (_, snap) {
        final m = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('system', style: _base.copyWith(color: AppColors.labelSystem)),
            _structRow(_top),
            m == null ? _loadingRow('cpu')
                : _colorRow('cpu',     _c2Bar(m.cpuPercent),  _cpuColor(m.cpuPercent)),
            _structRow(_mid),
            m == null ? _loadingRow('ram')
                : _colorRow('ram',     _c2Bar(m.ramPercent),  _ramColor(m.ramPercent)),
            _structRow(_mid),
            m == null ? _loadingRow('temp')
                : _colorRow('temp',    _c2Temp(m.deviceTempC), _tempColor(m.deviceTempC)),
            _structRow(_mid),
            m == null ? _loadingRow('net ↓')
                : _colorRow('net ↓',  _c2Speed(_formatSpeed(m.rxBytesPerSec)), _netColor(m.rxBytesPerSec)),
            _structRow(_mid),
            m == null ? _loadingRow('net ↑')
                : _colorRow('net ↑',  _c2Speed(_formatSpeed(m.txBytesPerSec)), _netColor(m.txBytesPerSec)),
            _structRow(_mid),
            m == null ? _loadingRow('battery')
                : _colorRow('battery', _c2Bar(m.batteryPercent, suffix: m.isCharging ? '⚡' : ''),
                    _battColor(m.batteryPercent, m.isCharging)),
            _structRow(_mid),
            m == null ? _loadingRow('storage')
                : _colorRow('storage', _c2Bar(m.storagePercent), _storageColor(m.storagePercent)),
            _structRow(_mid),
            m == null ? _loadingRow('wifi')
                : _colorRow('wifi', _c2Rssi(m.wifiRssi), _wifiColor(m.wifiRssi)),
            _structRow(_bottom),
          ],
        );
      },
    );
  }
}
