package com.rishabh.terminal_launcher

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.os.SystemClock
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class SystemMetricsPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    // ── network EMA ───────────────────────────────────────────────────────────
    private val unsupported = TrafficStats.UNSUPPORTED.toLong()
    private var prevRxBytes: Long = TrafficStats.getTotalRxBytes().takeIf { it != unsupported } ?: 0L
    private var prevTxBytes: Long = TrafficStats.getTotalTxBytes().takeIf { it != unsupported } ?: 0L
    private var prevNetTimeMs: Long = SystemClock.elapsedRealtime()
    private var smoothRx: Double = 0.0
    private var smoothTx: Double = 0.0
    private val netAlpha = 0.3

    // ── CPU: own process /proc/self/stat ─────────────────────────────────────
    // /proc/stat (system-wide) is blocked by SELinux on Android 9+.
    // /proc/self/stat (own process) is always readable — shows launcher CPU %.
    private var prevProcUtime: Long = 0L
    private var prevProcStime: Long = 0L
    private var prevProcWallMs: Long = SystemClock.elapsedRealtime()
    private val clkTck: Long = 100L // Linux USER_HZ = 100 ticks/sec on Android

    // ── RAM EMA ───────────────────────────────────────────────────────────────
    private var smoothRam: Double = -1.0
    private val ramAlpha = 0.4

    fun register(channelName: String) {
        // Seed CPU baseline on first registration
        readProcSelfStat()?.let { (u, s) ->
            prevProcUtime  = u
            prevProcStime  = s
            prevProcWallMs = SystemClock.elapsedRealtime()
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSnapshot" -> {
                    try {
                        result.success(buildSnapshot())
                    } catch (e: Exception) {
                        result.error("SNAPSHOT_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun buildSnapshot(): Map<String, Any> {
        updateNetworkSpeeds()
        return mapOf(
            "cpuPercent"     to cpuPercent(),
            "ramPercent"     to ramPercent(),
            "rxBytesPerSec"  to smoothRx.toLong(),
            "txBytesPerSec"  to smoothTx.toLong(),
            "batteryPercent" to batteryPercent(),
            "isCharging"     to isCharging(),
            "storagePercent" to storagePercent(),
            "deviceTempC"    to deviceTempC(),
            "wifiRssi"       to wifiRssi()
        )
    }

    // ── CPU (/proc/self/stat — own process) ───────────────────────────────────

    private fun readProcSelfStat(): Pair<Long, Long>? {
        return try {
            val text  = File("/proc/self/stat").readText()
            // Format: pid (name) state ... utime(14) stime(15) ... (1-indexed)
            // Name field may contain spaces/parens; find closing ')' to skip it
            val start = text.lastIndexOf(')') + 2
            val parts = text.substring(start).trim().split(" ")
            // After ')': state(0) ppid(1) ... utime(11) stime(12)
            val utime = parts[11].toLong()
            val stime = parts[12].toLong()
            Pair(utime, stime)
        } catch (_: Exception) { null }
    }

    private fun cpuPercent(): Int {
        val stat = readProcSelfStat() ?: return 0
        val (utime, stime) = stat
        val now = SystemClock.elapsedRealtime()

        val deltaWork = ((utime + stime) - (prevProcUtime + prevProcStime)).coerceAtLeast(0L)
        val deltaWallMs = (now - prevProcWallMs).coerceAtLeast(1L)

        prevProcUtime  = utime
        prevProcStime  = stime
        prevProcWallMs = now

        // Convert ticks to ms: ticks * 1000 / clkTck
        val workMs = deltaWork * 1000L / clkTck
        return ((workMs.toFloat() / deltaWallMs) * 100f).toInt().coerceIn(0, 100)
    }

    // ── RAM ───────────────────────────────────────────────────────────────────

    private fun ramPercent(): Int {
        val am   = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        val raw = (info.totalMem - info.availMem).toDouble() / info.totalMem * 100.0
        smoothRam = if (smoothRam < 0) raw else ramAlpha * raw + (1.0 - ramAlpha) * smoothRam
        return smoothRam.toInt().coerceIn(0, 100)
    }

    // ── Network ───────────────────────────────────────────────────────────────

    private fun updateNetworkSpeeds() {
        val rx = TrafficStats.getTotalRxBytes()
        val tx = TrafficStats.getTotalTxBytes()
        if (rx == unsupported || tx == unsupported) return

        val now     = SystemClock.elapsedRealtime()
        val elapsed = (now - prevNetTimeMs).coerceAtLeast(1L)
        val rawRx   = if (rx >= prevRxBytes) (rx - prevRxBytes) * 1000L / elapsed else 0L
        val rawTx   = if (tx >= prevTxBytes) (tx - prevTxBytes) * 1000L / elapsed else 0L

        smoothRx = netAlpha * rawRx + (1.0 - netAlpha) * smoothRx
        smoothTx = netAlpha * rawTx + (1.0 - netAlpha) * smoothTx

        prevRxBytes   = rx
        prevTxBytes   = tx
        prevNetTimeMs = now
    }

    // ── Battery ───────────────────────────────────────────────────────────────

    private fun batteryPercent(): Int {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun isCharging(): Boolean {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return bm.isCharging
    }

    // ── Device temperature (battery sensor — correlates with CPU heat) ────────

    private fun deviceTempC(): Int {
        val intent = context.registerReceiver(
            null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        ) ?: return 0
        val tenths = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
        return tenths / 10 // tenths of a degree → whole degrees Celsius
    }

    // ── WiFi RSSI ─────────────────────────────────────────────────────────────

    private fun wifiRssi(): Int {
        return try {
            // Use ConnectivityManager to verify WiFi active — no location permission needed
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return 0
            val caps = cm.getNetworkCapabilities(network) ?: return 0
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return 0
            // getRssi() is not location-gated; networkId is — don't check networkId
            @Suppress("DEPRECATION")
            val rssi = (context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
                .connectionInfo?.rssi ?: return 0
            if (rssi == Int.MIN_VALUE) 0 else rssi
        } catch (_: Exception) { 0 }
    }

    // ── Storage ───────────────────────────────────────────────────────────────

    private fun storagePercent(): Int {
        val sf    = StatFs(Environment.getDataDirectory().absolutePath)
        val total = sf.totalBytes
        val used  = total - sf.freeBytes
        return ((used.toFloat() / total) * 100).toInt()
    }
}
