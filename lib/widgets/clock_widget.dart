import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terminal_launcher/models/system_metrics.dart';
import 'package:terminal_launcher/services/system_metrics_service.dart';
import 'package:terminal_launcher/utils/constants.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  late DateTime _now;
  late AnimationController _chargeController;
  StreamSubscription<SystemMetrics>? _metricsSub;
  bool _isCharging = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(AppDurations.clockRefresh, (_) {
      setState(() => _now = DateTime.now());
    });

    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _metricsSub = SystemMetricsService().stream.listen((m) {
      if (mounted && m.isCharging != _isCharging) {
        setState(() => _isCharging = m.isCharging);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _chargeController.dispose();
    _metricsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('HH:mm').format(_now),
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: AppSizes.timeFontSize,
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMM').format(_now),
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: AppSizes.dateFontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        if (_isCharging) ...[
          const SizedBox(height: 4),
          FadeTransition(
            opacity: _chargeController,
            child: const Text(
              '⚡ charging',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: AppSizes.hintFontSize,
                fontWeight: FontWeight.w400,
                color: AppColors.metricCharging,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
