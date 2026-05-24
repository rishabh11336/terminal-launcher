package com.rishabh.terminal_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private val APP_CHANNEL       = "com.rishabh.terminal_launcher/apps"
    private val PLATFORM_CHANNEL  = "com.rishabh.terminal_launcher/platform"
    private val PACKAGE_CHANNEL   = "com.rishabh.terminal_launcher/packages"
    private val NOTIF_METHOD      = "com.rishabh.terminal_launcher/notifications"
    private val NOTIF_EVENTS      = "com.rishabh.terminal_launcher/notification_counts"
    private val USAGE_CHANNEL     = "com.rishabh.terminal_launcher/usagestats"
    private val SYSMETRICS_CHANNEL = "com.rishabh.terminal_launcher/sysmetrics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppQueryPlugin(this, flutterEngine).register(APP_CHANNEL)
        LockScreenPlugin(this, flutterEngine).register(PLATFORM_CHANNEL) // handles expand + lock + admin
        PackageEventPlugin(this, flutterEngine).register(PACKAGE_CHANNEL)
        NotificationPlugin(this, flutterEngine).register(NOTIF_METHOD, NOTIF_EVENTS)
        UsageStatsPlugin(this, flutterEngine).register(USAGE_CHANNEL)
        SystemMetricsPlugin(this, flutterEngine).register(SYSMETRICS_CHANNEL)
    }

    // Intercept back button: do nothing on home screen (standard launcher behavior)
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Do not call super — prevent exiting the launcher
    }
}
