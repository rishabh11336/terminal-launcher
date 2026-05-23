import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terminal_launcher/utils/constants.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // 30s interval — we only show HH:MM, no per-second update needed
    _timer = Timer.periodic(AppDurations.clockRefresh, (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
      ],
    );
  }
}
