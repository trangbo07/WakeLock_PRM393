package com.prm393.wakelock_prm393

import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the `wakelock/volume` MethodChannel that pins the alarm stream to max
 * and swallows the hardware volume keys while an alarm is ringing, so the user
 * cannot silence it by turning the volume down ("chặn quyền giảm âm lượng").
 */
class MainActivity : FlutterActivity() {
    private val volumeChannelName = "wakelock/volume"
    private val ringtoneChannelName = "wakelock/ringtones"
    private var volumeLocked = false

    private val audioManager: AudioManager
        get() = getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val systemRingtones by lazy { SystemRingtones(applicationContext) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, volumeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lockToMax" -> {
                        volumeLocked = true
                        pinAlarmVolumeToMax()
                        runOnUiThread { setRingingWindowFlags(true) }
                        result.success(null)
                    }
                    "unlock" -> {
                        volumeLocked = false
                        runOnUiThread { setRingingWindowFlags(false) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ringtoneChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "list" -> result.success(systemRingtones.list())
                    "defaultAlarmUri" -> result.success(systemRingtones.defaultAlarmUri())
                    "preview" -> {
                        systemRingtones.preview(call.argument("uri"))
                        result.success(null)
                    }
                    "stopPreview" -> {
                        systemRingtones.stopPreview()
                        result.success(null)
                    }
                    "startAlarm" -> {
                        systemRingtones.startAlarm(
                            call.argument("uri"),
                            call.argument<Boolean>("escalate") ?: true,
                        )
                        result.success(null)
                    }
                    "stopAlarm" -> {
                        systemRingtones.stopAlarm()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pinAlarmVolumeToMax() {
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
    }

    /**
     * While ringing: keep the screen on and force the activity above the
     * keyguard so the alarm can't be hidden away. Cleared on unlock.
     */
    private fun setRingingWindowFlags(ringing: Boolean) {
        val flags = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        if (ringing) window.addFlags(flags) else window.clearFlags(flags)
    }

    /**
     * While locked, consume volume up/down so Android never lowers the alarm
     * stream, and re-assert max volume on every press for good measure.
     */
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (volumeLocked) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    if (event.action == KeyEvent.ACTION_DOWN) pinAlarmVolumeToMax()
                    return true // swallow the key
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }
}
