import 'dart:async';
import 'package:flutter/services.dart';
import 'package:terminal_launcher/models/system_metrics.dart';

class SystemMetricsService {
  static final SystemMetricsService _instance = SystemMetricsService._internal();
  factory SystemMetricsService() => _instance;

  static const _channel = MethodChannel('com.rishabh.terminal_launcher/sysmetrics');

  late final StreamController<SystemMetrics> _controller =
      StreamController<SystemMetrics>.broadcast();
  Timer? _timer;
  bool _disposed = false;

  SystemMetricsService._internal() {
    _fetchAndEmit();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchAndEmit());
  }

  Stream<SystemMetrics> get stream => _controller.stream;

  Future<SystemMetrics> getMetrics() async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>('getSnapshot');
    return SystemMetrics.fromMap(raw!);
  }

  Future<void> _fetchAndEmit() async {
    if (_disposed) return;
    try {
      final metrics = await getMetrics();
      if (!_disposed && !_controller.isClosed) _controller.add(metrics);
    } catch (_) {
      // silently ignore — table stays at last value
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controller.close();
  }
}
