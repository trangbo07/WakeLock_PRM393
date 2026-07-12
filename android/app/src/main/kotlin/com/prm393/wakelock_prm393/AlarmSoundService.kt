package com.prm393.wakelock_prm393

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that plays the alarm sound in a loop and shows a
 * full-screen notification bringing up the dismiss UI. Running as a service
 * (not in the Flutter UI) is what makes the alarm ring RELIABLY and keep
 * looping regardless of what the user does, until the dismiss task is done.
 */
class AlarmSoundService : Service() {
    companion object {
        const val actionRing = "com.prm393.wakelock_prm393.action.RING"
        const val actionStop = "com.prm393.wakelock_prm393.action.STOP"
        const val extraSoundUri = "soundUri"
        const val extraEscalate = "escalate"
        const val extraLabel = "label"
        const val extraAlarmId = "alarmId"

        private const val channelId = "wakelock_alarm_ring"
        private const val notificationId = 91234
    }

    private val ringtones by lazy { SystemRingtones(applicationContext) }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionStop) {
            stopEverything()
            return START_NOT_STICKY
        }

        val soundUri = intent?.getStringExtra(extraSoundUri)
        val escalate = intent?.getBooleanExtra(extraEscalate, true) ?: true
        val label = intent?.getStringExtra(extraLabel) ?: "Báo thức"
        val alarmId = intent?.getStringExtra(extraAlarmId) ?: ""

        startForeground(notificationId, buildNotification(label, alarmId))
        ringtones.startAlarm(soundUri, escalate)
        return START_STICKY
    }

    private fun stopEverything() {
        ringtones.stopAlarm()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        ringtones.stopAlarm()
        super.onDestroy()
    }

    private fun buildNotification(label: String, alarmId: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Báo thức đang reo",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(null, null) // the service plays the sound, not the channel
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }

        // Full-screen intent brings up the ringing/dismiss UI over the lock screen.
        val fullScreen = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(extraAlarmId, alarmId)
        }
        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pending = PendingIntent.getActivity(this, 0, fullScreen, piFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(label)
            .setContentText("Hoàn thành nhiệm vụ để tắt báo thức")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(pending, true)
            .setContentIntent(pending)
            .build()
    }
}
