import 'package:flutter/material.dart';
import 'package:terminal_launcher/utils/constants.dart';

class TerminalCursor extends StatefulWidget {
  const TerminalCursor({super.key});

  @override
  State<TerminalCursor> createState() => _TerminalCursorState();
}

class _TerminalCursorState extends State<TerminalCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.cursorBlink,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('> ', style: _style),
        FadeTransition(
          opacity: _controller,
          child: const Text('_', style: _style),
        ),
      ],
    );
  }

  static const _style = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: AppSizes.cursorFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
}
