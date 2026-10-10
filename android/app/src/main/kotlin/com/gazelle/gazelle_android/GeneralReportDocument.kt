package com.gazelle.gazelle_android

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import java.io.ByteArrayOutputStream

/** Renders an immutable, account-scoped snapshot supplied by Flutter. */
object GeneralReportDocument {
    private const val WIDTH = 1190
    private const val HEIGHT = 1684
    private const val ROWS_PER_PAGE = 25

    fun render(args: Map<*, *>, pdf: Boolean): ByteArray {
        val rows = table(args, "rows", 7)
        require(rows.size <= 367) { "Период слишком большой" }
        val detailed = args["detail"] == true
        val pages = 1 + if (detailed) (rows.size + ROWS_PER_PAGE - 1) / ROWS_PER_PAGE else 0
        if (pdf) {
            val document = PdfDocument()
            try {
                for (index in 0 until pages) {
                    val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, index + 1).create())
                    page.canvas.save()
                    page.canvas.scale(0.5f, 0.5f)
                    draw(page.canvas, args, rows, index, pages)
                    page.canvas.restore()
                    document.finishPage(page)
                }
                return ByteArrayOutputStream().use { out -> document.writeTo(out); out.toByteArray() }
            } finally { document.close() }
        }
        val index = (args["page"] as? Number)?.toInt() ?: 0
        require(index in 0 until pages)
        val bitmap = Bitmap.createBitmap(WIDTH, HEIGHT, Bitmap.Config.ARGB_8888)
        try {
            draw(Canvas(bitmap), args, rows, index, pages)
            return ByteArrayOutputStream().use { out ->
                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, out))
                out.toByteArray()
            }
        } finally { bitmap.recycle() }
    }

    private fun table(args: Map<*, *>, key: String, columns: Int): List<List<String>> =
        (args[key] as? List<*> ?: error("Нет поля $key")).map { item ->
            val row = item as? List<*> ?: error("Строка $key")
            require(row.size == columns)
            row.map { it?.toString().orEmpty().take(180) }
        }

    private fun draw(canvas: Canvas, args: Map<*, *>, rows: List<List<String>>, page: Int, pages: Int) {
        canvas.drawColor(Color.WHITE)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val ink = Color.rgb(30, 39, 44)
        val muted = Color.rgb(91, 100, 104)
        val line = Color.rgb(202, 206, 204)
        val gold = Color.rgb(147, 111, 61)
        fun text(value: String, x: Float, y: Float, size: Float = 23f,
                 width: Float = 1050f, bold: Boolean = false, color: Int = ink) {
            paint.color = color
            paint.textSize = size
            paint.typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
            paint.textAlign = Paint.Align.LEFT
            val measured = paint.measureText(value)
            if (measured > width && measured > 0) paint.textSize *= width / measured
            canvas.drawText(value, x, y, paint)
        }
        fun rule(y: Float) {
            paint.color = line; paint.strokeWidth = 1f
            canvas.drawLine(64f, y, 1126f, y, paint)
        }
        fun title(value: String, y: Float) {
            paint.color = Color.rgb(240, 241, 237)
            canvas.drawRect(64f, y - 30f, 1126f, y + 12f, paint)
            text(value, 80f, y, 23f, bold = true)
        }
        text("МЕЛЬНИЦА", 64f, 77f, 23f, bold = true, color = gold)
        text("ОТЧЁТ О РАБОТЕ ВОДИТЕЛЯ", 64f, 124f, 34f, bold = true)
        text(args["name"].toString(), 64f, 168f, 26f, bold = true)
        text(args["period"].toString(), 64f, 205f, 23f, color = muted)
        rule(229f)
        if (page == 0) {
            title("ИТОГИ РАБОТЫ", 277f)
            var y = 324f
            val summary = table(args, "summary", 2)
            require(summary.size <= 9)
            for (row in summary) {
                text(row[0], 80f, y, width = 710f)
                text(row[1], 830f, y, width = 278f, bold = true)
                rule(y + 14f); y += 47f
            }
            title("НАЧИСЛЕНИЯ, ₸", 803f)
            y = 851f
            val pay = table(args, "pay", 2)
            require(pay.size <= 7)
            pay.forEachIndexed { i, row ->
                val total = i == pay.lastIndex
                text(row[0], 80f, y, if (total) 25f else 23f, width = 710f, bold = total)
                text(row[1], 830f, y, if (total) 27f else 23f, width = 278f, bold = total)
                rule(y + 14f); y += 47f
            }
            val notes = args["notes"] as? List<*> ?: emptyList<Any>()
            require(notes.size <= 8)
            y = 1240f
            notes.forEach { text(it.toString(), 64f, y, 19f, color = muted); y += 31f }
        } else {
            title("ДЕТАЛИЗАЦИЯ ПО ДНЯМ", 277f)
            val widths = listOf(168f, 106f, 80f, 163f, 163f, 132f, 250f)
            val headers = listOf("Дата", "Часы", "Рейсы", "Город, т", "Район, т", "Км", "Начислено, ₸")
            fun row(cells: List<String>, y: Float, header: Boolean = false, total: Boolean = false) {
                if (header || total) {
                    paint.color = Color.rgb(240, 241, 237)
                    canvas.drawRect(64f, y, 1126f, y + 43f, paint)
                }
                var x = 64f
                cells.forEachIndexed { i, cell ->
                    text(cell, x + 8f, y + 28f, if (header) 19f else 21f,
                        width = widths[i] - 16f, bold = header || total)
                    paint.color = line; paint.strokeWidth = 1f
                    canvas.drawLine(x, y, x, y + 43f, paint)
                    x += widths[i]
                }
                paint.color = line
                canvas.drawLine(1126f, y, 1126f, y + 43f, paint)
                rule(y); rule(y + 43f)
            }
            row(headers, 312f, header = true)
            var y = 355f
            rows.drop((page - 1) * ROWS_PER_PAGE).take(ROWS_PER_PAGE).forEach {
                row(it, y); y += 43f
            }
            if (page == pages - 1) {
                val total = (args["total"] as? List<*>)?.map { it.toString() } ?: error("Нет итогов")
                require(total.size == 7)
                row(total, y, total = true)
            }
            text("* Неполные данные: пояснения на первой странице.", 64f, 1510f, 18f, color = muted)
        }
        rule(1583f)
        text(args["created"].toString(), 64f, 1618f, 18f, color = muted)
        text("Страница ${page + 1} из $pages", 910f, 1618f, 18f, width = 216f, color = muted)
    }
}
