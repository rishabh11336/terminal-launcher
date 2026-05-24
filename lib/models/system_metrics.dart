class SystemMetrics {
  final int cpuPercent;
  final int ramPercent;
  final int rxBytesPerSec;
  final int txBytesPerSec;
  final int batteryPercent;
  final bool isCharging;
  final int storagePercent;
  final int deviceTempC;
  final int wifiRssi; // dBm, 0 = not connected / unavailable

  const SystemMetrics({
    required this.cpuPercent,
    required this.ramPercent,
    required this.rxBytesPerSec,
    required this.txBytesPerSec,
    required this.batteryPercent,
    required this.isCharging,
    required this.storagePercent,
    required this.deviceTempC,
    required this.wifiRssi,
  });

  factory SystemMetrics.fromMap(Map<Object?, Object?> m) {
    return SystemMetrics(
      cpuPercent:     (m['cpuPercent']     as num).toInt(),
      ramPercent:     (m['ramPercent']     as num).toInt(),
      rxBytesPerSec:  (m['rxBytesPerSec']  as num).toInt(),
      txBytesPerSec:  (m['txBytesPerSec']  as num).toInt(),
      batteryPercent: (m['batteryPercent'] as num).toInt(),
      isCharging:     m['isCharging']      as bool,
      storagePercent: (m['storagePercent'] as num).toInt(),
      deviceTempC:    (m['deviceTempC']    as num).toInt(),
      wifiRssi:       (m['wifiRssi']       as num).toInt(),
    );
  }
}
