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
            "render" -> Thread {
                try {
                    val bytes = render(args)
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
                        putExtra(Intent.EXTRA_TITLE, "avans_${System.currentTimeMillis()}.png")
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
        val bitmap = Bitmap.createBitmap(1800, 2546, Bitmap.Config.ARGB_8888)
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
            val summary = listOf("Из кассы получено" to v("received"), "Расход" to v("expenses"), "Остаток" to v("balance"))
            var sx = 70f
            for ((label, value) in summary) {
                box(sx, 290f, 1660f / 3, 125f)
                text(label, sx + 14f, 302f, 520, 40, 26f)
                text("$value ₸", sx + 14f, 350f, 520, 52, 34f, true)
                sx += 1660f / 3
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
            row(headings, 455f, 58, true)
            for (i in 0 until 16) {
                val values = (rows.getOrNull(i) as? List<*>)?.map { it?.toString() ?: "" } ?: emptyList()
                row(values, 513f + i * 108, 108)
            }
            text("Итого по отчёту: ${v("expenses")} ₸", 70f, 2270f, 1660, 60, 32f, true)
            text("Подотчётное лицо ____________________     Проверил ____________________", 70f, 2370f, 1660, 60)
            text("Лист ${v("page")} из ${v("pages")} · ${v("status")}", 70f, 2470f, 1660, 40, 22f)
            return ByteArrayOutputStream().use { out ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, out))
                out.toByteArray()
            }
        } finally { bitmap.recycle() }
    }
}
