package com.prm393.wakelock_prm393

import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the `wakelock/volume` MethodChannel that pins the alarm stream to max
 * and swallows the hardware volume keys while an alarm is ringing, so the user
 * cannot silence it by turning the volume down ("chặn quyền giảm âm lượng").
 */
class MainActivity : FlutterActivity() {
    private val channelName = "wakelock/volume"
    private var volumeLocked = false

    private val audioManager: AudioManager
        get() = getSystemService(Context.AUDIO_SERVICE) as AudioManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lockToMax" -> {
                        volumeLocked = true
                        pinAlarmVolumeToMax()
                        result.success(null)
                    }
                    "unlock" -> {
                        volumeLocked = false
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
