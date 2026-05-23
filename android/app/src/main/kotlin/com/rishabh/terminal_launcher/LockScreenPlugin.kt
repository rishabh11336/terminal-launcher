package com.rishabh.terminal_launcher

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class LockScreenPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(channelName: String) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockScreen" -> {
                    try {
                        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
                                as DevicePolicyManager
                        val admin = ComponentName(context, LockScreenReceiver::class.java)
                        if (dpm.isAdminActive(admin)) {
                            dpm.lockNow()
                            result.success(null)
                        } else {
                            result.error(
                                "PERMISSION_DENIED",
                                "Device admin not granted. Enable in Settings > Security > Device Admin.",
                                null
                            )
                        }
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", e.message, null)
                    } catch (e: Exception) {
                        result.error("LOCK_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
