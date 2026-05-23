package com.rishabh.terminal_launcher

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

// Device admin receiver required for lockScreen feature (TRD Section 3.3)
class LockScreenReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {}
    override fun onDisabled(context: Context, intent: Intent) {}
}
