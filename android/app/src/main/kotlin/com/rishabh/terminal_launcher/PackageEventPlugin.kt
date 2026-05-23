package com.rishabh.terminal_launcher

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class PackageEventPlugin(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    fun register(channelName: String) {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                PackageBroadcastReceiver.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                PackageBroadcastReceiver.eventSink = null
            }
        })
    }
}
