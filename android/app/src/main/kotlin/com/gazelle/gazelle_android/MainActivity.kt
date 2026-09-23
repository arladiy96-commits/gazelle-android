package com.gazelle.gazelle_android

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var hoodPool: SoundPool? = null
    private var hoodSound = 0
    private var hoodStream = 0
    private var hoodReady = false
    private var hoodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val pool = SoundPool.Builder().setMaxStreams(1)
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            .build()
        hoodPool = pool
        pool.setOnLoadCompleteListener { _, _, status -> hoodReady = status == 0 }
        hoodSound = pool.load(this, R.raw.hood_open, 1)
        hoodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gazelle/hood_audio")
        hoodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    // Never queue a late sound after the visual opening has passed.
                    if (hoodReady) {
                        pool.stop(hoodStream)
                        hoodStream = pool.play(hoodSound, 0.48f, 0.48f, 1, 0, 1f)
                    }
                    result.success(null)
                }
                "stop" -> { pool.stop(hoodStream); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPause() {
        hoodPool?.autoPause()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        hoodChannel?.setMethodCallHandler(null)
        hoodChannel = null
        hoodReady = false
        hoodPool?.release()
        hoodPool = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
