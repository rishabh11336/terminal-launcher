package com.rishabh.terminal_launcher

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
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
                        val active = dpm.isAdminActive(admin)
                        Log.d("LockScreenPlugin", "lockNow called — isAdminActive: $active")
                        if (active) {
                            dpm.lockNow()
                            result.success(null)
                        } else {
                            result.error("ADMIN_NOT_ACTIVE", "Device admin not granted", null)
                        }
                    } catch (e: SecurityException) {
                        result.error("ADMIN_NOT_ACTIVE", e.message, null)
                    } catch (e: Exception) {
                        result.error("LOCK_FAILED", e.message, null)
                    }
                }
                "isAdminActive" -> {
                    val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
                            as DevicePolicyManager
                    val admin = ComponentName(context, LockScreenReceiver::class.java)
                    result.success(dpm.isAdminActive(admin))
                }
                "openDeviceAdminSettings" -> {
                    try {
                        val admin = ComponentName(context, LockScreenReceiver::class.java)
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
                            putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "Required to lock the screen from the launcher"
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ADMIN_INTENT_FAILED", e.message, null)
                    }
                }
                "expandNotifications" -> {
                    try {
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
