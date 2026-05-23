package com.rishabh.terminal_launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.EventChannel

class PackageBroadcastReceiver : BroadcastReceiver() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val packageName = intent.data?.schemeSpecificPart ?: return
        val event = when (intent.action) {
            Intent.ACTION_PACKAGE_ADDED ->
                mapOf("type" to "added", "package" to packageName)
            Intent.ACTION_PACKAGE_REMOVED ->
                mapOf("type" to "removed", "package" to packageName)
            else -> return
        }
        eventSink?.success(event)
    }
}
