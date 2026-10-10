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
        val sheets = (args["pages"] as? List<*>)?.map { raw ->
            val rows = raw as? List<*> ?: error("Нет строк")
            require(rows.size <= 24)
            rows.map { item ->
                val row = item as? List<*> ?: error("Строка")
                require(row.size == 5)
                row.map { it?.toString().orEmpty().take(240) }
            }
        } ?: error("Нет страниц")
        val pages = sheets.size
        require(pages in 1..1000) { "Нет данных или слишком большой отчёт" }
        if (pdf) {
            val document = PdfDocument()
            try {
                for (index in 0 until pages) {
                    val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, index + 1).create())
                    page.canvas.save()
                    page.canvas.scale(0.5f, 0.5f)
                    draw(page.canvas, args, sheets[index], index, pages)
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
            draw(Canvas(bitmap), args, sheets[index], index, pages)
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
        text("ОТЧЁТ ПО РЕЙСАМ И ТОННАЖУ", 64f, 124f, 34f, bold = true)
        text(args["name"].toString(), 64f, 168f, 26f, bold = true)
        text(args["period"].toString(), 64f, 205f, 23f, color = muted)
        rule(229f)
        val widths = listOf(532f, 190f, 190f, 150f)
        fun row(cells: List<String>, y: Float, header: Boolean = false, total: Boolean = false) {
            if (header || total) {
                paint.color = Color.rgb(240, 241, 237)
                canvas.drawRect(64f, y, 1126f, y + 49f, paint)
            }
            var x = 64f
            cells.forEachIndexed { i, cell ->
                text(cell, x + 10f, y + 31f, if (header) 21f else 23f,
                    width = widths[i] - 20f, bold = header || total)
                paint.color = line; paint.strokeWidth = 1f
                canvas.drawLine(x, y, x, y + 49f, paint)
                x += widths[i]
            }
            paint.color = line
            canvas.drawLine(1126f, y, 1126f, y + 49f, paint)
            rule(y); rule(y + 49f)
        }
        row(listOf("Направление", "Город, кг", "Район, кг", "Платное"), 259f, header = true)
        var y = 308f
        for (entry in rows) {
            when (entry[0]) {
                "day" -> {
                    paint.color = Color.rgb(227, 232, 231)
                    canvas.drawRect(64f, y, 1126f, y + 49f, paint)
                    text(entry[1], 76f, y + 31f, 22f, width = 1038f, bold = true)
                    rule(y); rule(y + 49f)
                }
                "note" -> text(entry[1], 76f, y + 31f, 21f, width = 1038f, color = muted)
                else -> row(entry.drop(1), y, total = entry[0] == "total" || entry[0] == "grand")
            }
            y += 49f
        }
        text("В итогах столбец «Платное» — количество платных рейсов.", 64f, 1515f, 18f, color = muted)
        text("День указан по началу смены. Статус дня и платность — из журнала.", 64f, 1546f, 18f, color = muted)
        rule(1583f)
        text(args["created"].toString(), 64f, 1618f, 18f, color = muted)
        text("Страница ${page + 1} из $pages", 910f, 1618f, 18f, width = 216f, color = muted)
    }
}
