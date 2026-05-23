import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(AppDurations.clockRefresh, (_) => _refresh());
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

  String _connString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
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
