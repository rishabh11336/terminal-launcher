package com.rishabh.terminal_launcher

import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationCountService : NotificationListenerService() {

    companion object {
        private val _counts: MutableMap<String, Int> = mutableMapOf()
        private val mainHandler = Handler(Looper.getMainLooper())

        // Set by NotificationPlugin when EventChannel is listening
        var onCountsChanged: ((Map<String, Int>) -> Unit)? = null

        fun getCounts(): Map<String, Int> = _counts.toMap()
    }

    override fun onListenerConnected() {
        rebuildCounts()
        notifyFlutter()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        rebuildCounts()
        notifyFlutter()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        rebuildCounts()
        notifyFlutter()
    }

    private fun rebuildCounts() {
        _counts.clear()
        try {
            activeNotifications?.forEach { sbn ->
                val pkg = sbn.packageName
                _counts[pkg] = (_counts[pkg] ?: 0) + 1
            }
        } catch (_: Exception) { }
    }

    private fun notifyFlutter() {
        val snapshot = _counts.toMap()
        mainHandler.post {
            onCountsChanged?.invoke(snapshot)
        }
    }
}
