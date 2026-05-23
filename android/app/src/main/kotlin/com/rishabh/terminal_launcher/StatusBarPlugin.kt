package com.rishabh.terminal_launcher

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class StatusBarPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(channelName: String) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "expandNotifications" -> {
                    try {
                        // Hidden API via reflection — works on Pixel 7a Android 14
                        // If blocked in future OS update, fails gracefully (TRD Section 6.3 note)
                        @Suppress("WrongConstant")
                        val service = context.getSystemService("statusbar")
                        val method = service?.javaClass?.getMethod("expandNotificationsPanel")
                        method?.invoke(service)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("EXPAND_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
