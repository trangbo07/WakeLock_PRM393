package com.prm393.wakelock_prm393

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Receives the "ring now" broadcast sent by the background alarm isolate (via
 * android_intent_plus) and starts [AlarmSoundService] as a foreground service.
 * A receiver is used because a broadcast can be delivered from the background
 * isolate, whereas a foreground service can only be started from a component.
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val service = Intent(context, AlarmSoundService::class.java).apply {
            action = AlarmSoundService.actionRing
            putExtra(AlarmSoundService.extraSoundUri, intent.getStringExtra(AlarmSoundService.extraSoundUri))
            putExtra(AlarmSoundService.extraEscalate, intent.getBooleanExtra(AlarmSoundService.extraEscalate, true))
            putExtra(AlarmSoundService.extraLabel, intent.getStringExtra(AlarmSoundService.extraLabel))
            putExtra(AlarmSoundService.extraAlarmId, intent.getStringExtra(AlarmSoundService.extraAlarmId))
        }
        ContextCompat.startForegroundService(context, service)
    }
}
