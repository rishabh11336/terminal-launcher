package com.rishabh.terminal_launcher

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AppQueryPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(channelName: String) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val pm = context.packageManager
                        val intent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val apps = pm.queryIntentActivities(intent, PackageManager.GET_META_DATA)
                        val list = apps.map { ri ->
                            mapOf(
                                "packageName" to ri.activityInfo.packageName,
                                "appName" to ri.loadLabel(pm).toString()
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("QUERY_FAILED", e.message, null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context.startActivity(launchIntent)
                            result.success(null)
                        } else {
                            result.error("LAUNCH_FAILED", "No launch intent for $packageName", null)
                        }
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
