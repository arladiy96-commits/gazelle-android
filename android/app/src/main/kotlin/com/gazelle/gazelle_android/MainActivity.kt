package com.gazelle.gazelle_android

import android.content.ClipData
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import androidx.core.content.FileProvider
import java.io.File
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MoneyShareFileProvider : FileProvider()

class MainActivity : FlutterActivity() {
    private var advanceChannel: MethodChannel? = null
    private val advanceExport by lazy { AdvanceImageExport(this) }
    private var moneyShareChannel: MethodChannel? = null
    private var sharingMoney = false
    private var hoodPool: SoundPool? = null
    private var hoodSound = 0
    private var hoodStream = 0
    private var hoodReady = false
    private var hoodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        advanceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melnitsa/advance_image")
        advanceChannel?.setMethodCallHandler { call, result ->
            advanceExport.handle(call.method, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>(), result)
        }
        moneyShareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melnitsa/money_share")
        moneyShareChannel?.setMethodCallHandler { call, result ->
            if (call.method != "share") {
                result.notImplemented()
            } else if (sharingMoney) {
                result.error("busy", "Покупюрник уже готовится", null)
            } else {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("invalid", "Нет данных подсчёта", null)
                } else {
                    sharingMoney = true
                    Thread {
                        try {
                            val file = createMoneySlip(args)
                            runOnUiThread {
                                try {
                                    if (isFinishing || isDestroyed) throw IllegalStateException("Экран закрыт")
                                    val uri = FileProvider.getUriForFile(this, "$packageName.money_files", file)
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = "image/png"
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        putExtra(Intent.EXTRA_SUBJECT, "Покупюрник — Мельница")
                                        clipData = ClipData.newRawUri("Покупюрник", uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    startActivity(Intent.createChooser(intent, "Поделиться покупюрником"))
                                    result.success(null)
                                } catch (e: Exception) {
                                    result.error("share_failed", "Не удалось открыть отправку", "${e.javaClass.simpleName}: ${e.message}")
                                } finally { sharingMoney = false }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                sharingMoney = false
                                result.error("export_failed", "Не удалось создать покупюрник", "${e.javaClass.simpleName}: ${e.message}")
                            }
                        }
                    }.start()
                }
            }
        }
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

    // Generates only a temporary export of the saved snapshot; never modifies the ledger.
    private fun createMoneySlip(args: Map<*, *>): File {
        val rows = args["rows"] as? List<*> ?: throw IllegalArgumentException("rows")
        require(rows.size <= 14)
        fun value(key: String) = (args[key] as? String ?: "").take(160)
        val width = 1080
        val rowHeight = 62f
        val hasKaspi = (value("kaspiCount").toIntOrNull() ?: 0) > 0
        val height = (610 + (if (hasKaspi) 90 else 0) + rows.size * rowHeight).toInt()
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.WHITE)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            fun text(value: String, x: Float, y: Float, size: Float = 30f,
                     bold: Boolean = false, right: Boolean = false, maxWidth: Float = 950f) {
                paint.color = Color.rgb(25, 29, 32)
                paint.typeface = if (bold) Typeface.create("sans-serif", Typeface.BOLD) else Typeface.create("sans-serif", Typeface.NORMAL)
                paint.textSize = size
                val measured = paint.measureText(value)
                if (measured > maxWidth) paint.textSize = size * maxWidth / measured
                paint.textAlign = if (right) Paint.Align.RIGHT else Paint.Align.LEFT
                canvas.drawText(value, x, y, paint)
            }
            fun rule(y: Float) {
                paint.color = Color.rgb(209, 213, 216)
                paint.strokeWidth = 1.5f
                canvas.drawLine(55f, y, 1025f, y, paint)
            }
            text("МЕЛЬНИЦА", 55f, 68f, 25f, true)
            text("ПОКУПЮРНИК", 55f, 126f, 44f, true)
            text(value("date"), 55f, 173f, 28f)
            paint.color = Color.rgb(236, 239, 241)
            canvas.drawRect(55f, 202f, 1025f, 266f, paint)
            text("Номинал, ₸", 75f, 244f, 28f, true)
            text("Количество, шт.", 650f, 244f, 28f, true, true, 300f)
            text("Сумма, ₸", 1005f, 244f, 28f, true, true)
            var y = 266f
            for (row in rows) {
                val cells = row as? List<*> ?: throw IllegalArgumentException("row")
                require(cells.size == 3)
                text(cells[0].toString().take(60), 75f, y + 42f, maxWidth = 280f)
                text(cells[1].toString().take(60), 650f, y + 42f, right = true, maxWidth = 280f)
                text(cells[2].toString().take(60), 1005f, y + 42f, right = true, maxWidth = 320f)
                y += rowHeight
                rule(y)
            }
            y += 60f
            text("ИТОГО НАЛИЧНЫХ", 55f, y, 30f, true, maxWidth = 430f)
            text(value("cash") + " ₸", 1025f, y, 36f, true, true, 490f)
            y += 60f
            text("По накладным (" + value("invoiceCount") + ")", 55f, y, maxWidth = 450f)
            text(value("invoices") + " ₸", 1025f, y, 32f, false, true, 490f)
            y += 32f
            rule(y)
            y += 59f
            text(value("difference"), 55f, y, 36f, true)
            if (hasKaspi) {
                y += 30f
                rule(y)
                y += 60f
                text("Каспи (" + value("kaspiCount") + " накл.)", 55f, y, maxWidth = 450f)
                text(value("kaspi") + " ₸", 1025f, y, 32f, false, true, 490f)
            }
            y += 62f
            text("Сформировано из сохранённого подсчёта", 55f, y, 23f)
            val directory = File(cacheDir, "money_exports")
            if (!directory.exists() && !directory.mkdirs()) throw IllegalStateException("cache")
            // Keep recent files available while another app is reading them.
            directory.listFiles()?.filter { it.isFile && it.lastModified() < System.currentTimeMillis() - 7L * 86400000L }
                ?.forEach { it.delete() }
            val file = File.createTempFile("pokupyurnik_", ".png", directory)
            file.outputStream().use { require(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
            return file
        } finally { bitmap.recycle() }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!advanceExport.onResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onPause() {
        hoodPool?.autoPause()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        advanceChannel?.setMethodCallHandler(null)
        advanceChannel = null
        moneyShareChannel?.setMethodCallHandler(null)
        moneyShareChannel = null
        hoodChannel?.setMethodCallHandler(null)
        hoodChannel = null
        hoodReady = false
        hoodPool?.release()
        hoodPool = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
