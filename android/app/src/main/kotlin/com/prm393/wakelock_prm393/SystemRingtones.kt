package com.prm393.wakelock_prm393

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper

/**
 * Exposes the device's real built-in alarm sounds via RingtoneManager, so the
 * app uses genuine Android ringtones (no bundled/redistributed audio).
 *
 * "default" is a sentinel meaning the system's default alarm sound.
 */
class SystemRingtones(private val context: Context) {

    private var preview: Ringtone? = null
    private var alarm: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())
    private var escalateStep: Runnable? = null

    private val audioManager: AudioManager
        get() = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val alarmAttributes: AudioAttributes =
        AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

    /** The system default alarm sound as a concrete content:// URI string. */
    fun defaultAlarmUri(): String =
        (RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
            .toString()

    /** All alarm sounds on the device, the default (concrete uri) first. */
    fun list(): List<Map<String, String>> {
        val result = mutableListOf(
            mapOf("uri" to defaultAlarmUri(), "title" to "Mặc định hệ thống"),
        )
        val manager = RingtoneManager(context).apply { setType(RingtoneManager.TYPE_ALARM) }
        val cursor = manager.cursor
        while (cursor.moveToNext()) {
            val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
            val uri = manager.getRingtoneUri(cursor.position).toString()
            result.add(mapOf("uri" to uri, "title" to title))
        }
        return result
    }

    private fun resolve(uriStr: String?): Uri? {
        if (uriStr.isNullOrEmpty() || uriStr == "default") {
            return RingtoneManager.getActualDefaultRingtoneUri(
                context, RingtoneManager.TYPE_ALARM,
            ) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        }
        // A user-picked file is stored as an absolute path.
        if (uriStr.startsWith("/")) return Uri.fromFile(java.io.File(uriStr))
        return Uri.parse(uriStr)
    }

    fun preview(uriStr: String?) {
        stopPreview()
        val uri = resolve(uriStr) ?: return
        preview = RingtoneManager.getRingtone(context, uri)?.apply {
            audioAttributes = alarmAttributes
            play()
        }
    }

    fun stopPreview() {
        preview?.stop()
        preview = null
    }

    /** Loop the chosen alarm sound, optionally ramping volume up over time. */
    fun startAlarm(uriStr: String?, escalate: Boolean) {
        stopAlarm()
        val uri = resolve(uriStr) ?: return
        alarm = RingtoneManager.getRingtone(context, uri)?.apply {
            audioAttributes = alarmAttributes
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
            play()
        }
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        if (escalate) {
            var level = (max * 0.3).toInt().coerceAtLeast(1)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, level, 0)
            escalateStep = object : Runnable {
                override fun run() {
                    if (alarm == null || level >= max) return
                    level++
                    audioManager.setStreamVolume(AudioManager.STREAM_ALARM, level, 0)
                    handler.postDelayed(this, 3000)
                }
            }.also { handler.postDelayed(it, 3000) }
        } else {
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
        }
    }

    fun stopAlarm() {
        escalateStep?.let { handler.removeCallbacks(it) }
        escalateStep = null
        alarm?.stop()
        alarm = null
    }
}
