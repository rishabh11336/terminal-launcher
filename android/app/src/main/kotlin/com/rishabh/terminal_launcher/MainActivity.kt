package com.rishabh.terminal_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private val APP_CHANNEL      = "com.rishabh.terminal_launcher/apps"
    private val PLATFORM_CHANNEL = "com.rishabh.terminal_launcher/platform"
    private val PACKAGE_CHANNEL  = "com.rishabh.terminal_launcher/packages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppQueryPlugin(this, flutterEngine).register(APP_CHANNEL)
        StatusBarPlugin(this, flutterEngine).register(PLATFORM_CHANNEL)
        LockScreenPlugin(this, flutterEngine).register(PLATFORM_CHANNEL)
        PackageEventPlugin(this, flutterEngine).register(PACKAGE_CHANNEL)
    }

    // Intercept back button: do nothing on home screen (standard launcher behavior)
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Do not call super — prevent exiting the launcher
    }
}
