package com.gazelle.gazelle_android

import android.graphics.*
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.ByteArrayOutputStream

object GasImageForm {
    fun render(args: Map<*, *>): ByteArray {
        fun v(key: String) = args[key]?.toString() ?: ""
        val rows = args["rows"] as? List<*> ?: emptyList<Any>()
        require(rows.size <= 31)
        val bitmap = Bitmap.createBitmap(1800, 2546, Bitmap.Config.ARGB_8888)
        try {
            val c = Canvas(bitmap)
            c.drawColor(Color.WHITE)
            val pen = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK; strokeWidth = 1.5f }
            fun line(x: Float, y: Float, x2: Float, y2: Float) = c.drawLine(x,y,x2,y2,pen)
            fun box(x: Float,y: Float,w: Float,h: Float) {
                pen.style=Paint.Style.STROKE; c.drawRect(x,y,x+w,y+h,pen); pen.style=Paint.Style.FILL
            }
            fun text(s: String,x: Float,y: Float,w: Int,h: Int,size: Float=25f,bold: Boolean=false) {
                val p=TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                    color=Color.BLACK; textSize=size
                    typeface=Typeface.create("serif",if(bold) Typeface.BOLD else Typeface.NORMAL)
                }
                fun layout()=StaticLayout.Builder.obtain(s,0,s.length,p,w)
                    .setIncludePad(false).setAlignment(Layout.Alignment.ALIGN_NORMAL).build()
                var l=layout()
                while(l.height>h && p.textSize>9f){p.textSize-=1f;l=layout()}
                c.save();c.translate(x,y);l.draw(c);c.restore()
            }
            text(v("organization").ifBlank { "ТОО ____________________________________" }, 300f,60f,1200,65,36f,true)
            text("Карточка водителя",600f,125f,900,60,38f,true)
            text("Месяц: ${v("month")}",100f,205f,1550,50,29f)
            text("Марка техники: ${v("vehicle").ifBlank { "____________________" }}",100f,265f,1550,50,29f)
            text("ФИО водителя: ${v("name")}",100f,325f,1550,50,29f)
            text("Норма расхода ГСМ: ${args["norm"] ?: "28 л / 100 км"}",1040f,385f,650,45,26f)
            text("Остаток ГСМ на начало месяца",100f,440f,1050,50,29f)
            box(1170f,435f,400f,57f);text(v("opening"),1185f,445f,370,40,29f,true)
            val distanceMode = args["distanceMode"] == true
            val widths=if(distanceMode) intArrayOf(160,225,460,235,520) else intArrayOf(160,225,230,230,235,520)
            val start=100f;val top=535f;val header=114f
            var x=start
            widths.forEach { w -> box(x,top,w.toFloat(),header);x+=w }
            // Merge the two odometer cells in the first header tier.
            if (!distanceMode) {
            pen.color=Color.WHITE;pen.strokeWidth=3f;line(715f,top+2,715f,top+49);pen.color=Color.BLACK;pen.strokeWidth=1.5f
            }
            text("Дата",112f,572f,136,65,26f,true)
            text("Отработано часов\n(моточасов)",272f,552f,201,90,24f)
            if (distanceMode) {
                text("Пробег за день, км", 497f, 571f, 436, 65, 28f, true)
            } else {
            text("Спидометр",590f,543f,340,40,26f,true)
            line(485f,585f,945f,585f)
            text("Данные на\nначало дня",497f,593f,206,50,23f)
            text("Данные на\nконец дня",727f,593f,206,50,23f)
            }
            text("ГСМ · газ\nЗаправлено, л",957f,553f,211,90,25f)
            text("Выполняемые работы",1192f,571f,496,65,26f)
            val rowHeight=44f
            for(i in 0 until 31){
                val cells=(rows.getOrNull(i) as? List<*>)?.map{it?.toString()?:""}?:emptyList()
                var rx=start;val y=top+header+i*rowHeight
                widths.forEachIndexed { j,w ->
                    box(rx,y,w.toFloat(),rowHeight)
                    text(cells.getOrElse(j){""},rx+7,y+6,w-14,32,24f)
                    rx+=w
                }
            }
            val bottom=top+header+31*rowHeight
            box(start,bottom,845f,60f);box(945f,bottom,235f,60f);box(1180f,bottom,520f,60f)
            text("ИТОГО заправлено ГСМ",420f,bottom+14,510,42,27f,true)
            text(v("gas"),957f,bottom+14,211,42,27f,true)
            if (distanceMode) text("Итого пробег: ${v("km")} км", 1192f, bottom+14, 496, 42, 25f, true)
            text("Остаток ГСМ на конец месяца",100f,2115f,1050,50,29f)
            box(1170f,2110f,400f,57f);text(v("closing"),1185f,2120f,370,40,29f,true)
            text(v("note"),100f,2190f,1600,80,22f)
            text("Подпись Водителя",100f,2300f,740,55,30f);line(1000f,2340f,1550f,2340f)
            text("Подпись Главного инженера",100f,2400f,840,55,30f);line(1000f,2440f,1550f,2440f)
            return ByteArrayOutputStream().use{out->check(bitmap.compress(Bitmap.CompressFormat.PNG,100,out));out.toByteArray()}
        } finally { bitmap.recycle() }
    }
}
