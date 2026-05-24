import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:terminal_launcher/services/icon_cache_service.dart';

// Grayscale matrix — luminosity method
const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0,      0,      0,      1, 0,
]);

class AppIconWidget extends StatefulWidget {
  final String packageName;
  final double size;
  final int notifCount;

  const AppIconWidget({
    super.key,
    required this.packageName,
    this.size = 20,
    this.notifCount = 0,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  Uint8List? _icon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppIconWidget old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName) {
      setState(() => _icon = null);
      _load();
    }
  }

  Future<void> _load() async {
    final icon = await IconCacheService().getIcon(widget.packageName);
    if (mounted && icon != null) {
      setState(() => _icon = icon);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget icon;

    if (_icon != null) {
      icon = ColorFiltered(
        colorFilter: _grayscale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            _icon!,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      );
    } else {
      icon = SizedBox(width: widget.size, height: widget.size);
    }

    if (widget.notifCount <= 0) return icon;

    // Badge overlay — top-right corner
    final label = widget.notifCount > 9 ? '9+' : '${widget.notifCount}';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            constraints: const BoxConstraints(minWidth: 13, minHeight: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88), // accentGreen
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
