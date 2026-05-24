package com.rishabh.terminal_launcher

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class UsageStatsPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(channelName: String) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> result.success(isPermissionGranted())
                "requestPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(null)
                }
                "getRecentApps" -> {
                    val count = call.argument<Int>("count") ?: 3
                    val handler = android.os.Handler(android.os.Looper.getMainLooper())
                    Thread {
                        try {
                            val data = queryRecentApps(count)
                            handler.post { result.success(data) }
                        } catch (e: Exception) {
                            handler.post { result.error("QUERY_FAILED", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isPermissionGranted(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun queryRecentApps(count: Int): List<Map<String, Any>> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 7L * 24 * 60 * 60 * 1000 // last 7 days

        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, end)
        val pm = context.packageManager
        val selfPkg = context.packageName

        return stats
            .filter { stat ->
                stat.lastTimeUsed > 0 &&
                stat.packageName != selfPkg &&
                pm.getLaunchIntentForPackage(stat.packageName) != null
            }
            .sortedByDescending { it.lastTimeUsed }
            .distinctBy { it.packageName }
            .take(count)
            .mapNotNull { stat ->
                try {
                    val info = pm.getApplicationInfo(stat.packageName, 0)
                    mapOf(
                        "packageName" to stat.packageName,
                        "appName"     to pm.getApplicationLabel(info).toString(),
                        "lastUsed"    to stat.lastTimeUsed
                    )
                } catch (_: PackageManager.NameNotFoundException) {
                    null
                }
            }
    }
}
