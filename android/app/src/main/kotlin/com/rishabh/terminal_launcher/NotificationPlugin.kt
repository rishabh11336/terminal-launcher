package com.rishabh.terminal_launcher

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NotificationPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(methodChannelName: String, eventChannelName: String) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> result.success(isListenerEnabled())
                "requestPermission" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(null)
                }
                "getCounts" -> result.success(NotificationCountService.getCounts())
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                // Push current counts immediately on subscribe
                events.success(NotificationCountService.getCounts())
                // Wire callback for future updates
                NotificationCountService.onCountsChanged = { counts ->
                    events.success(counts)
                }
            }

            override fun onCancel(arguments: Any?) {
                NotificationCountService.onCountsChanged = null
            }
        })
    }

    private fun isListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        )
        return flat?.contains(context.packageName) == true
    }
}
