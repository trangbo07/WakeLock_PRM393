package com.prm393.wakelock_prm393

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Flashbang effects while the alarm rings: strobe the camera flashlight and a
 * relentless, escalating vibration. Runs from [AlarmSoundService] so it keeps
 * going regardless of the UI, until the alarm is dismissed.
 */
class AlarmEffects(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())

    // ---- Torch strobe ----
    private val cameraManager by lazy {
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    }
    private var flashId: String? = null
    private var flashOn = false
    private var flashRunnable: Runnable? = null

    private fun flashCameraId(): String? = try {
        cameraManager.cameraIdList.firstOrNull { id ->
            cameraManager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
    } catch (_: Exception) {
        null
    }

    fun startFlash() {
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)) return
        flashId = flashCameraId() ?: return
        flashRunnable = object : Runnable {
            override fun run() {
                flashOn = !flashOn
                try {
                    cameraManager.setTorchMode(flashId!!, flashOn)
                } catch (_: Exception) {
                }
                handler.postDelayed(this, 350) // ~3 blinks/sec
            }
        }.also { handler.post(it) }
    }

    fun stopFlash() {
        flashRunnable?.let { handler.removeCallbacks(it) }
        flashRunnable = null
        flashId?.let { try { cameraManager.setTorchMode(it, false) } catch (_: Exception) {} }
        flashOn = false
    }

    // ---- Escalating vibration ----
    private val vibrator: Vibrator by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager)
                .defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }
    private var vibeRunnable: Runnable? = null

    fun startVibration() {
        if (!vibrator.hasVibrator()) return
        var step = 0
        vibeRunnable = object : Runnable {
            override fun run() {
                // Buzz longer + gaps shorter as time passes (more urgent).
                val on = (300L + step * 120L).coerceAtMost(1300L)
                val off = (500L - step * 45L).coerceAtLeast(120L)
                val pattern = longArrayOf(0, on, off)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(pattern, 0)
                }
                if (step < 8) {
                    step++
                    handler.postDelayed(this, 4000) // ramp up every 4s
                }
            }
        }.also { handler.post(it) }
    }

    fun stopVibration() {
        vibeRunnable?.let { handler.removeCallbacks(it) }
        vibeRunnable = null
        try { vibrator.cancel() } catch (_: Exception) {}
    }

    fun stopAll() {
        stopFlash()
        stopVibration()
    }
}
