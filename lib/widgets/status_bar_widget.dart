import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:terminal_launcher/models/system_metrics.dart';
import 'package:terminal_launcher/services/system_metrics_service.dart';
import 'package:terminal_launcher/utils/constants.dart';

class StatusBarWidget extends StatefulWidget {
  const StatusBarWidget({super.key});

  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();
}

class _StatusBarWidgetState extends State<StatusBarWidget> {
  final _battery = Battery();
  final _connectivity = Connectivity();

  int _batteryLevel = 0;
  String _connLabel = '';
  int _wifiRssi = 0;
  Timer? _refreshTimer;
  StreamSubscription<SystemMetrics>? _metricsSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(AppDurations.clockRefresh, (_) => _refresh());
    _metricsSub = SystemMetricsService().stream.listen((m) {
      if (mounted && m.wifiRssi != _wifiRssi) {
        setState(() => _wifiRssi = m.wifiRssi);
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final level = await _battery.batteryLevel;
      final result = await _connectivity.checkConnectivity();
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _connLabel = _connString(result);
      });
    } catch (_) {
      // Silently ignore — status bar is best-effort
    }
  }

  String _connString(dynamic result) {
    // connectivity_plus 5.x returns List<ConnectivityResult>
    final r = result is List ? (result.isNotEmpty ? result.first : null) : result;
    switch (r) {
      case ConnectivityResult.wifi:
        return _wifiRssi != 0 ? '${_wifiRssi}dBm' : 'wifi';
      case ConnectivityResult.mobile:
        return '4g';
      case ConnectivityResult.ethernet:
        return 'eth';
      default:
        return 'off';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _metricsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_batteryLevel%  $_connLabel',
      style: const TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: AppSizes.hintFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );
  }
}
