package com.gazelle.gazelle_android

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import java.io.ByteArrayOutputStream

/** The same millimetre display list drives preview and vector PDF. */
object InvoiceDocument {
    fun render(context: Context, args: Map<*, *>): Map<String, Any> {
        val pages = args["pages"] as? List<*> ?: error("Нет страниц")
        require(pages.isNotEmpty() && pages.size <= 20) { "Слишком много страниц" }
        val regular = Typeface.createFromAsset(context.assets, "invoice_fonts/LiberationSans-Regular.ttf")
        val bold = Typeface.createFromAsset(context.assets, "invoice_fonts/LiberationSans-Bold.ttf")
        val pdf = PdfDocument()
        val previews = ArrayList<ByteArray>()
        try {
            pages.forEachIndexed { index, raw ->
                val commands = raw as? List<*> ?: error("Некорректная страница")
                require(commands.size <= 4000)
                val page = pdf.startPage(PdfDocument.PageInfo.Builder(595, 842, index + 1).create())
                page.canvas.save()
                page.canvas.scale(72f / 25.4f, 72f / 25.4f)
                draw(page.canvas, commands, regular, bold)
                page.canvas.restore()
                pdf.finishPage(page)
                val bitmap = Bitmap.createBitmap(1050, 1485, Bitmap.Config.ARGB_8888)
                try {
                    val canvas = Canvas(bitmap)
                    canvas.drawColor(Color.WHITE)
                    canvas.scale(5f, 5f)
                    draw(canvas, commands, regular, bold)
                    previews.add(ByteArrayOutputStream().use { out ->
                        check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, out))
                        out.toByteArray()
                    })
                } finally { bitmap.recycle() }
            }
            val bytes = ByteArrayOutputStream().use { out -> pdf.writeTo(out); out.toByteArray() }
            return mapOf("pdf" to bytes, "images" to previews)
        } finally { pdf.close() }
    }
    private fun draw(canvas: Canvas, commands: List<*>, regular: Typeface, bold: Typeface) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK }
        for (raw in commands) {
            val c = raw as? Map<*, *> ?: error("Некорректный элемент")
            fun n(key: String): Float = (c[key] as? Number)?.toFloat()?.also {
                require(it.isFinite())
            } ?: error("Нет координаты $key")
            when (c["op"]) {
                "line" -> {
                    paint.strokeWidth = n("weight")
                    canvas.drawLine(n("x"), n("y"), n("x2"), n("y2"), paint)
                }
                "text" -> {
                    val text = c["s"] as? String ?: ""
                    paint.typeface = if (c["bold"] == true) bold else regular
                    paint.textSize = n("size") * 25.4f / 72f
                    paint.textScaleX = 1f
                    val width = n("width")
                    val measured = paint.measureText(text)
                    // Preserve height; compress only exceptionally long fields.
                    if (measured > width && measured > 0) paint.textScaleX = width / measured
                    val align = c["align"]
                    paint.textAlign = when (align) {
                        "right" -> Paint.Align.RIGHT
                        "center" -> Paint.Align.CENTER
                        else -> Paint.Align.LEFT
                    }
                    val x = n("x") + when (align) { "right" -> width; "center" -> width / 2; else -> 0f }
                    canvas.drawText(text, x, n("y"), paint)
                }
                else -> error("Неизвестный элемент")
            }
        }
    }
}
