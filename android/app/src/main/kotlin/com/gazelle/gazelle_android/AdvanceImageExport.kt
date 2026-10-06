package com.gazelle.gazelle_android

import android.app.Activity
import android.content.Intent
import android.graphics.*
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/** Independent image export: no access to the application journal. */
class AdvanceImageExport(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private val requestCode = 4381

    fun handle(method: String, args: Map<*, *>, result: MethodChannel.Result) {
        when (method) {
            "render", "renderGas" -> Thread {
                try {
                    val bytes = if (method == "renderGas") GasImageForm.render(args) else render(args)
                    activity.runOnUiThread { result.success(bytes) }
                } catch (e: Exception) {
                    activity.runOnUiThread { result.error("render", e.message, null) }
                }
            }.start()
            "save" -> {
                if (pending != null) { result.error("busy", "Сохранение уже открыто", null); return }
                val bytes = args["bytes"] as? ByteArray
                if (bytes == null) { result.error("empty", "Нет изображения", null); return }
                pending = result
                pendingBytes = bytes
                try {
                    activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/png"
                        putExtra(Intent.EXTRA_TITLE, "${if (args["kind"] == "gas") "gas_report" else "avans"}_${System.currentTimeMillis()}.png")
                    }, requestCode)
                } catch (e: Exception) {
                    pending = null; pendingBytes = null
                    result.error("save", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun onResult(code: Int, status: Int, data: Intent?): Boolean {
        if (code != requestCode) return false
        val reply = pending ?: return true
        val bytes = pendingBytes
        pending = null; pendingBytes = null
        val uri = data?.data
        if (status != Activity.RESULT_OK || uri == null || bytes == null) {
            reply.success(false); return true
        }
        Thread {
            try {
                val stream = activity.contentResolver.openOutputStream(uri) ?: error("Не удалось открыть файл")
                stream.use { it.write(bytes) }
                activity.runOnUiThread { reply.success(true) }
            } catch (e: Exception) {
                activity.runOnUiThread { reply.error("save", e.message, null) }
            }
        }.start()
        return true
    }

    private fun render(args: Map<*, *>): ByteArray {
        val rows = args["rows"] as? List<*> ?: emptyList<Any>()
        require(rows.size <= 16)
        fun v(key: String) = args[key]?.toString() ?: ""
        val daily = (args["daily"] as? List<*>)?.map { item ->
            (item as? List<*>)?.map { it?.toString() ?: "" } ?: emptyList()
        } ?: emptyList()
        require(daily.size <= 16)
        val measure = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = 27f; typeface = Typeface.create("serif", Typeface.NORMAL)
        }
        val dailyHeights = daily.map { day ->
            val expression = day.getOrElse(1) { "" }
            val layout = StaticLayout.Builder.obtain(expression, 0, expression.length, measure, 574)
                .setIncludePad(false).build()
            maxOf(52, layout.height + 20)
        }
        val summaryHeight = 78 + maxOf(64, dailyHeights.sum()) + 76
        val extra = summaryHeight - 125
        val bitmap = Bitmap.createBitmap(1800, 2546 + extra, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.WHITE)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK; strokeWidth = 2f }
            fun box(x: Float, y: Float, w: Float, h: Float) {
                paint.style = Paint.Style.STROKE
                canvas.drawRect(x, y, x + w, y + h, paint)
                paint.style = Paint.Style.FILL
            }
            fun text(value: String, x: Float, y: Float, w: Int, h: Int, size: Float = 27f, bold: Boolean = false) {
                val p = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.BLACK; textSize = size
                    typeface = Typeface.create("serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
                }
                fun layout() = StaticLayout.Builder.obtain(value, 0, value.length, p, w)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL).setIncludePad(false).build()
                var l = layout()
                while (l.height > h && p.textSize > 10f) { p.textSize -= 1f; l = layout() }
                canvas.save(); canvas.translate(x, y); l.draw(canvas); canvas.restore()
            }
            text("АВАНСОВЫЙ ОТЧЁТ № ${v("number")}", 70f, 70f, 1080, 70, 44f, true)
            text("Мельничный комплекс", 1200f, 78f, 530, 60, 30f)
            text(v("name"), 70f, 145f, 1660, 65, 32f)
            text("Период: ${v("period")}", 70f, 214f, 1660, 55)
            // Paper form: cash total | date | additions | date | daily expense | balance.
            val summaryWidths = intArrayOf(260, 185, 590, 185, 240, 200)
            val labels = listOf("Из кассы\nполучено", "Дата", "Сумма", "Дата", "Расход", "Остаток")
            var sx = 70f
            summaryWidths.forEachIndexed { i, width ->
                box(sx, 290f, width.toFloat(), summaryHeight.toFloat())
                text(labels[i], sx + 8, 300f, width - 16, 64, 26f)
                sx += width
            }
            canvas.drawLine(70f, 368f, 1730f, 368f, paint)
            text(v("received"), 78f, 380f, 244, 60, 30f, true)
            var dayY = 368f
            for ((index, day) in daily.withIndex()) {
                val h = dailyHeights[index]
                text(day.getOrElse(0) { "" }, 338f, dayY + 10, 169, h - 16)
                text(day.getOrElse(1) { "" }, 523f, dayY + 10, 574, h - 16)
                text(day.getOrElse(0) { "" }, 1113f, dayY + 10, 169, h - 16)
                text(day.getOrElse(2) { "" }, 1298f, dayY + 10, 224, h - 16)
                dayY += h
            }
            val totalY = 290f + summaryHeight - 76
            canvas.drawLine(1290f, totalY, 1530f, totalY, paint)
            if (args["dailyContinues"] == true) {
                text("Продолжение на следующем листе", 338f, totalY + 12, 930, 54, 24f)
            } else {
                text("Итого по всем датам", 523f, totalY + 12, 574, 54, 26f, true)
                text(v("expenses"), 1298f, totalY + 12, 224, 54, 28f, true)
                text(v("balance"), 1538f, totalY + 12, 184, 54, 28f, true)
            }
            val widths = intArrayOf(65, 155, 500, 140, 220, 240, 340)
            val headings = listOf("№", "Дата", "Наименование", "Кол-во", "Цена", "Сумма", "Направление")
            fun row(values: List<String>, y: Float, height: Int, header: Boolean = false) {
                var x = 70f
                widths.forEachIndexed { i, width ->
                    box(x, y, width.toFloat(), height.toFloat())
                    text(values.getOrElse(i) { "" }, x + 8, y + 8, width - 16, height - 16,
                        if (header) 24f else 26f, header)
                    x += width
                }
            }
            row(headings, 455f + extra, 58, true)
            for (i in 0 until 16) {
                val values = (rows.getOrNull(i) as? List<*>)?.map { it?.toString() ?: "" } ?: emptyList()
                row(values, 513f + extra + i * 108, 108)
            }
            text("Итого по отчёту: ${v("expenses")} тг", 70f, 2270f + extra, 1660, 60, 32f, true)
            text("Подотчётное лицо ____________________     Проверил ____________________", 70f, 2370f + extra, 1660, 60)
            text("Лист ${v("page")} из ${v("pages")} · ${v("status")}", 70f, 2470f + extra, 1660, 40, 22f)
            return ByteArrayOutputStream().use { out ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, out))
                out.toByteArray()
            }
        } finally { bitmap.recycle() }
    }
}
