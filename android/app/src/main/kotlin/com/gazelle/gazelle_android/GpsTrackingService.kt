package com.gazelle.gazelle_android

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.location.*
import android.os.*
import org.json.JSONObject
import java.util.UUID
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import io.flutter.plugin.common.MethodChannel

/** All service, DB and channel work uses one queue, including start/stop barriers. */
internal object GpsWorker {
    private val thread = HandlerThread("melnitsa-gps").apply { start() }
    val handler = Handler(thread.looper)
    val main = Handler(Looper.getMainLooper())
}

internal object GpsGate {
    private var cachedAccount: String? = null
    private var cachedShift: String? = null
    private var cachedJournal: String? = null
    private var cachedOpen = false
    fun account(context: Context, account: String): Boolean {
        val p = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return p.getString("flutter.melnitsa_session_v1", null) == account
    }
    @Synchronized fun open(context: Context, account: String, shift: String): Boolean = try {
        val p = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!account(context, account) || !EmployeeLocationSync.permits(context, account) || EmployeeLocationSync.closed(context, account, shift)) false else {
            val raw = p.getString("flutter.gazelle_miniapp_sandbox_v2_account_$account", "{}") ?: "{}"
            if (cachedAccount == account && cachedShift == shift && cachedJournal == raw) cachedOpen else {
                val rows = JSONObject(JSONObject(raw).optString("journal", "{}")).optJSONArray("shifts")
                val open = (0 until (rows?.length() ?: 0)).any { i ->
                    val s = rows!!.getJSONObject(i)
                    s.optString("id") == shift && s.isNull("end") && s.optString("gpsStatus", "active") == "active"
                }
                cachedAccount = account; cachedShift = shift; cachedJournal = raw; cachedOpen = open
                open
            }
        }
    } catch (_: Exception) { false }
    fun fine(c: Context) = c.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    fun background(c: Context) = Build.VERSION.SDK_INT < 29 ||
        c.checkSelfPermission(Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED
}

/** Isolated from Flutter's cached SharedPreferences. Never rewrites the journal. */
internal class GpsDatabase(private val context: Context) : SQLiteOpenHelper(context, "melnitsa_gps_v2.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE tracks(account TEXT NOT NULL, shift TEXT NOT NULL, token TEXT NOT NULL, metres REAL NOT NULL DEFAULT 0, gaps INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'waiting', updated INTEGER NOT NULL, PRIMARY KEY(account,shift))")
        db.execSQL("CREATE TABLE points(seq INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL, shift TEXT NOT NULL, lat REAL NOT NULL, lng REAL NOT NULL, accuracy REAL NOT NULL, speed REAL, wall INTEGER NOT NULL, broken INTEGER NOT NULL)")
        db.execSQL("CREATE INDEX route_points ON points(account,shift,seq)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    fun resetAccount(account: String) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            db.delete("points", "account=?", arrayOf(account))
            db.delete("tracks", "account=?", arrayOf(account))
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
    }
    fun ensure(account: String, shift: String) {
        writableDatabase.execSQL("INSERT OR IGNORE INTO tracks(account,shift,token,updated) VALUES(?,?,?,?)", arrayOf<Any>(account, shift, UUID.randomUUID().toString(), System.currentTimeMillis()))
    }
    fun status(account: String, shift: String, value: String) {
        writableDatabase.execSQL("UPDATE tracks SET status=? WHERE account=? AND shift=? AND status<>?", arrayOf(value, account, shift, value))
    }
    fun append(account: String, shift: String, point: GpsAccepted) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            val p = point.fix
            val hadPoint = db.rawQuery("SELECT 1 FROM points WHERE account=? AND shift=? LIMIT 1", arrayOf(account, shift)).use { it.moveToFirst() }
            db.execSQL("INSERT INTO points(account,shift,lat,lng,accuracy,speed,wall,broken) VALUES(?,?,?,?,?,?,?,?)",
                arrayOf<Any?>(account, shift, p.lat, p.lng, p.accuracy, p.speed, p.wall, if (point.newSegment) 1 else 0))
            db.execSQL("UPDATE tracks SET metres=metres+?, gaps=gaps+?, updated=?, status='tracking' WHERE account=? AND shift=?",
                arrayOf<Any>(point.metres, if (point.newSegment && hadPoint) 1 else 0, p.wall, account, shift))
            db.setTransactionSuccessful()
        } finally { db.endTransaction() }
    }
    fun snapshots(account: String): List<Map<String, Any>> = readableDatabase.rawQuery(
        "SELECT shift,token,metres,gaps,status,updated FROM tracks WHERE account=?", arrayOf(account)
    ).use { c -> buildList {
        while (c.moveToNext()) add(mapOf("shiftId" to c.getString(0), "token" to c.getString(1),
            "metres" to c.getDouble(2), "gaps" to c.getInt(3), "status" to c.getString(4), "updated" to c.getLong(5)))
    } }
    fun route(account: String, shift: String): Map<String, Any> {
        val db = readableDatabase
        val count = db.rawQuery("SELECT COUNT(*) FROM points WHERE account=? AND shift=?", arrayOf(account,shift)).use { it.moveToFirst(); it.getInt(0) }
        // Only visual downsampling. The full route and full distance stay on disk.
        val stride = (count / 4000).coerceAtLeast(1)
        val dates = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
        val points = db.rawQuery("SELECT lat,lng,accuracy,speed,wall,broken FROM points WHERE account=? AND shift=? AND (seq % ?=0 OR broken=1 OR seq=(SELECT MAX(seq) FROM points WHERE account=? AND shift=?)) ORDER BY seq",
            arrayOf(account,shift,stride.toString(),account,shift)).use { c -> buildList<Map<String,Any>> {
            while(c.moveToNext()) add(mapOf("lat" to c.getDouble(0), "lng" to c.getDouble(1), "accuracy" to c.getDouble(2),
                "speed" to c.getDouble(3), "time" to dates.format(Date(c.getLong(4))), "breakBefore" to (c.getInt(5) != 0)))
        } }
        val snapshot = snapshots(account).firstOrNull { it["shiftId"] == shift }
        return mapOf("deviceId" to EmployeeLocationSync.deviceId(context), "distanceKm" to ((snapshot?.get("metres") as? Double ?: 0.0)/1000), "points" to points,
            "gaps" to (snapshot?.get("gaps") ?: 0), "status" to (snapshot?.get("status") ?: "stopped"))
    }
}

class GpsTrackingService : Service(), LocationListener {
    private lateinit var locations: LocationManager
    private lateinit var db: GpsDatabase
    private var account: String? = null
    private var shift: String? = null
    internal fun owns(a: String, s: String) = account == a && shift == s
    private var registered = false
    private var storageError = false
    private var lastReceived = 0L
    private var lastNotification = 0L
    private var wake: PowerManager.WakeLock? = null
    private val filter = GpsDistanceFilter()
    private val preferences by lazy { getSharedPreferences("melnitsa_gps_service", MODE_PRIVATE) }
    private val journalListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == "flutter.melnitsa_session_v1" || key?.startsWith("flutter.gazelle_miniapp_sandbox_v2_account_") == true) {
            GpsWorker.handler.post { if (account != null && !valid()) halt() }
        }
    }
    private val watchdog = object : Runnable {
        override fun run() {
            if (account == null) return
            if (!valid()) { halt(); return }
            if (storageError) {
                try { db.ensure(account!!,shift!!); storageError = false }
                catch (_: Exception) {
                    notifyProgress()
                    GpsWorker.handler.postDelayed(this,10000)
                    return
                }
            }
            if (!GpsGate.fine(this@GpsTrackingService)) {
                setStatus("permission"); unregister(); releaseWake()
            } else if (!locations.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                setStatus("gps_off"); unregister(); releaseWake()
            } else {
                if (wake?.isHeld != true) wake?.acquire(10 * 60 * 1000L)
                if (!registered || SystemClock.elapsedRealtime() - lastReceived > 60000) {
                    unregister(); subscribe()
                }
                if (lastReceived > 0 && SystemClock.elapsedRealtime() - lastReceived > 15000) setStatus("signal_lost")
            }
            val a = account; val s = shift
            if (a != null && s != null) EmployeeLocationSync.tick(this@GpsTrackingService, a, s, db)
            notifyProgress()
            GpsWorker.handler.postDelayed(this, 10000)
        }
    }
    override fun onCreate() {
        super.onCreate()
        locations = getSystemService(LOCATION_SERVICE) as LocationManager
        db = GpsDatabase(this)
        wake = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "$packageName:gps").apply { setReferenceCounted(false) }
        if (Build.VERSION.SDK_INT >= 26) (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
            NotificationChannel(CHANNEL, "GPS открытой смены", NotificationManager.IMPORTANCE_LOW).apply { description = "Пробег записывается, пока смена открыта"; setShowBadge(false) })
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE).registerOnSharedPreferenceChangeListener(journalListener)
        instance = this
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Required immediately, before any disk work or GNSS startup.
        try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(NOTIFICATION, notification("Запуск GPS…"), ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            else startForeground(NOTIFICATION, notification("Запуск GPS…"))
        } catch (_: Exception) { stopSelf(); return START_NOT_STICKY }
        val a = intent?.getStringExtra("account") ?: preferences.getString("account", null)
        val s = intent?.getStringExtra("shift") ?: preferences.getString("shift", null)
        GpsWorker.handler.post {
            if (a.isNullOrBlank() || s.isNullOrBlank() || !GpsGate.open(this,a,s)) {
                if (account == null) halt()
                return@post
            }
            if (account == a && shift == s) return@post
            if (account != null) halt(stopService = false)
            account = a; shift = s
            try { db.ensure(a,s) } catch (_: Exception) {
                storageError = true
                (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIFICATION,
                    notification("Ошибка сохранения GPS — проверьте свободное место"))
            }
            preferences.edit().putString("account",a).putString("shift",s).commit()
            filter.interrupt()
            lastReceived = 0
            GpsWorker.handler.removeCallbacks(watchdog)
            watchdog.run()
        }
        return START_STICKY
    }
    private fun valid(): Boolean = account?.let { a -> shift?.let { GpsGate.open(this,a,it) } } == true
    private fun subscribe() {
        try {
            locations.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 0f, this, GpsWorker.handler.looper)
            registered = true
            lastReceived = SystemClock.elapsedRealtime()
            setStatus("waiting")
        } catch (_: SecurityException) { setStatus("permission") }
          catch (_: IllegalArgumentException) { setStatus("gps_off") }
    }
    private fun unregister() { if (registered) { locations.removeUpdates(this); registered = false }; filter.interrupt() }
    override fun onLocationChanged(location: Location) {
        if (!valid()) { halt(); return }
        if (location.provider != LocationManager.GPS_PROVIDER) return
        val now = SystemClock.elapsedRealtime()
        val p = GpsFix(location.latitude, location.longitude, if(location.hasAccuracy()) location.accuracy.toDouble() else Double.NaN,
            if(location.hasSpeed()) location.speed.toDouble() else null,
            if(Build.VERSION.SDK_INT >= 26 && location.hasSpeedAccuracy()) location.speedAccuracyMetersPerSecond.toDouble() else null,
            location.elapsedRealtimeNanos / 1000000L, location.time)
        val accepted = filter.offer(p, now)
        if (now - p.elapsed in 0..10000 && p.accuracy in 0.01..30.0) {
            lastReceived = now
            setStatus("tracking")
        } else setStatus("weak_signal")
        if (accepted != null) {
            try { db.append(account!!,shift!!,accepted); storageError = false }
            catch (_: Exception) { storageError = true; setStatus("storage_error"); filter.interrupt() }
        }
        notifyProgress()
    }
    override fun onProviderDisabled(provider: String) { if (provider == LocationManager.GPS_PROVIDER) { setStatus("gps_off"); filter.interrupt() } }
    override fun onProviderEnabled(provider: String) { if (provider == LocationManager.GPS_PROVIDER) { GpsWorker.handler.removeCallbacks(watchdog); watchdog.run() } }
    @Deprecated("Old Android callback") override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
    private fun setStatus(status: String) {
        val a = account ?: return; val s = shift ?: return
        try { db.status(a,s,if (storageError) "storage_error" else status) }
        catch (_: Exception) { storageError = true }
    }
    private fun releaseWake() { if (wake?.isHeld == true) wake?.release() }
    internal fun halt(stopService: Boolean = true) {
        GpsWorker.handler.removeCallbacks(watchdog)
        unregister(); releaseWake()
        setStatus("stopped")
        account = null; shift = null
        preferences.edit().clear().commit()
        if (stopService) { stopForeground(STOP_FOREGROUND_REMOVE); stopSelf() }
    }
    private fun notification(message: String): Notification {
        val intent = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this,CHANNEL) else Notification.Builder(this)
        return b.setSmallIcon(android.R.drawable.ic_menu_mylocation).setContentTitle("Мельница · GPS смены")
            .setContentText(if (EmployeeLocationSync.sharing(this)) "$message · маршрут доступен владельцу" else message).setContentIntent(intent).setOngoing(true).setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE).setShowWhen(false).build()
    }
    private fun notifyProgress() {
        if (SystemClock.elapsedRealtime() - lastNotification < 5000) return
        lastNotification = SystemClock.elapsedRealtime()
        val a = account ?: return
        val row = try { db.snapshots(a).firstOrNull { it["shiftId"] == shift } } catch (_: Exception) { null }
        if (storageError || row == null) {
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIFICATION,
                notification("Ошибка сохранения GPS — проверьте свободное место"))
            return
        }
        val text = when (row["status"]) {
            "tracking" -> "Запись пробега"
            "permission" -> "Нужно разрешить точное местоположение"
            "gps_off" -> "Включите GPS на телефоне"
            "storage_error" -> "Ошибка сохранения GPS — откройте приложение"
            else -> "Ожидание точного сигнала GPS"
        }
        val km = (row["metres"] as Double) / 1000
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(NOTIFICATION,notification("$text · %.2f км".format(Locale.getDefault(),km)))
    }
    override fun onDestroy() {
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE).unregisterOnSharedPreferenceChangeListener(journalListener)
        if (instance === this) instance = null
        GpsWorker.handler.post {
            GpsWorker.handler.removeCallbacks(watchdog)
            unregister(); releaseWake(); db.close()
        }
        super.onDestroy()
    }
    companion object {
        private const val CHANNEL = "melnitsa_shift_gps"
        private const val NOTIFICATION = 7311
        @Volatile internal var instance: GpsTrackingService? = null
    }
}

/** Restore only a previously running, still-open shift, with background permission. */
class GpsRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in listOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED)) return
        if (!GpsGate.fine(context) || !GpsGate.background(context)) return
        val prefs = context.getSharedPreferences("melnitsa_gps_service", Context.MODE_PRIVATE)
        val a = prefs.getString("account",null) ?: return
        val s = prefs.getString("shift",null) ?: return
        if (!GpsGate.open(context,a,s)) return
        try {
            val service = Intent(context,GpsTrackingService::class.java).putExtra("account",a).putExtra("shift",s)
            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(service) else context.startService(service)
        } catch (_: Exception) { /* Android can disallow a restart; next visible launch retries. */ }
    }
}

class GpsBridge(private val activity: Activity) {
    @Volatile var resumed = false
    private val db = GpsDatabase(activity.applicationContext)
    fun handle(method: String, args: Map<*, *>, result: MethodChannel.Result) {
        if (method == "notifications") {
            if (resumed && Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
                activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7312)
            result.success(null); return
        }
        if (method == "start" && !resumed) { result.error("background", "Откройте приложение для запуска GPS", null); return }
        if (method == "ownerRoute") {
            val actor = args["actor"] as? String
            val target = args["account"] as? String
            fun allowed(): Boolean = try {
                val prefs = activity.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val root = JSONObject(prefs.getString("flutter.melnitsa_accounts_v1", "{}") ?: "{}")
                val rows = root.optJSONArray("accounts")
                val admins = (0 until (rows?.length() ?: 0)).map { rows!!.getJSONObject(it) }.filter { it.optString("role") == "admin" }
                val owner = root.optString("ownerId").ifEmpty { if(admins.size == 1) admins[0].optString("id") else "" }
                !actor.isNullOrBlank() && !target.isNullOrBlank() && GpsGate.account(activity, actor) && owner == actor &&
                    admins.any { it.optString("id") == actor && it.optBoolean("active") }
            } catch (_: Exception) { false }
            if (!allowed()) { result.error("owner", "Доступно владельцу", null); return }
            GpsWorker.handler.post {
                try {
                    check(allowed()) { "Нет доступа" }
                    val route = db.route(target!!, args["shift"] as? String ?: error("Нет смены"))
                    GpsWorker.main.post { result.success(route) }
                } catch(e: Exception) { GpsWorker.main.post { result.error("owner", e.message, null) } }
            }
            return
        }
        val account = args["account"] as? String
        if (account.isNullOrBlank() || !GpsGate.account(activity,account)) {
            result.error("account", "Учётная запись изменилась",null); return
        }
        GpsWorker.handler.post {
            try {
                // Recheck after queueing: never disclose a previous account's tracks.
                check(GpsGate.account(activity,account)) { "Учётная запись изменилась" }
                val value: Any? = when(method) {
                    "configureServer" -> { EmployeeLocationSync.configure(activity, account, args); null }
                    "resetServerRoutes" -> {
                        EmployeeLocationSync.configure(activity, account, mapOf("paused" to true))
                        db.resetAccount(account)
                        check(activity.getSharedPreferences("melnitsa_closed_shifts", Context.MODE_PRIVATE)
                            .edit().remove(account).commit())
                        null
                    }
                    "start" -> {
                        val shift = args["shift"] as? String ?: error("Нет смены")
                        check(GpsGate.open(activity,account,shift)) { "Смена закрыта или GPS на паузе" }
                        check(GpsGate.fine(activity)) { "Разрешите точное местоположение" }
                        if (GpsTrackingService.instance?.owns(account,shift) == true) {
                            GpsWorker.main.post { result.success(null) }
                            return@post
                        }
                        val intent = Intent(activity,GpsTrackingService::class.java).putExtra("account",account).putExtra("shift",shift)
                        // Service startup must run while the Activity is visible.
                        GpsWorker.main.post {
                            try {
                                check(resumed) { "Откройте приложение для запуска GPS" }
                                if(Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent) else activity.startService(intent)
                                result.success(null)
                            } catch(e: Exception) { result.error("start",e.message,null) }
                        }
                        return@post
                    }
                    "stop" -> {
                        GpsTrackingService.instance?.halt()
                        activity.getSharedPreferences("melnitsa_gps_service",Context.MODE_PRIVATE).edit().clear().commit()
                        db.snapshots(account)
                    }
                    "snapshot" -> db.snapshots(account)
                    "route" -> db.route(account, args["shift"] as? String ?: error("Нет смены"))
                    else -> { GpsWorker.main.post { result.notImplemented() }; return@post }
                }
                GpsWorker.main.post { result.success(value) }
            } catch(e: Exception) { GpsWorker.main.post { result.error("gps",e.message,null) } }
        }
    }
    fun dispose() { GpsWorker.handler.post { db.close() } }
}
