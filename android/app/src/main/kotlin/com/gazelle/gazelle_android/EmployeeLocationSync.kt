package com.gazelle.gazelle_android

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.net.URL
import javax.net.ssl.HttpsURLConnection
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Token is encrypted using Android Keystore. No credentials in Flutter prefs. */
internal object EmployeeLocationSync {
    private const val ALIAS = "melnitsa_employee_api_v1"
    private val executor = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    private var lastRun = 0L
    private fun prefs(c: Context) = c.getSharedPreferences("melnitsa_employee_sync", Context.MODE_PRIVATE)
    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
    private fun encode(v: ByteArray) = Base64.encodeToString(v, Base64.NO_WRAP)
    private fun decode(v: String) = Base64.decode(v, Base64.NO_WRAP)
    private fun encrypt(value: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        return encode(cipher.iv) + ":" + encode(cipher.doFinal(value.toByteArray(Charsets.UTF_8)))
    }
    private fun decrypt(value: String): String {
        val parts = value.split(":")
        return Cipher.getInstance("AES/GCM/NoPadding").run {
            init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, decode(parts[0])))
            String(doFinal(decode(parts[1])), Charsets.UTF_8)
        }
    }
    @Synchronized fun deviceId(c: Context): String {
        val p = c.getSharedPreferences("melnitsa_gps_device", Context.MODE_PRIVATE)
        p.getString("id", null)?.let { return it }
        val value = java.util.UUID.randomUUID().toString()
        check(p.edit().putString("id", value).commit())
        return value
    }
    private fun millis(value: String): Long {
        for (pattern in listOf("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX")) {
            try { return SimpleDateFormat(pattern, Locale.US).apply { timeZone=TimeZone.getTimeZone("UTC"); isLenient=false }.parse(value)?.time ?: 0L } catch (_: Exception) {}
        }
        return 0L
    }
    fun configure(c: Context, account: String, args: Map<*, *>) {
        if (args["paused"] == true) {
            check(prefs(c).edit().clear().putString("account", account)
                .putBoolean("allowed", false).putBoolean("revoked", true).commit())
            GpsTrackingService.instance?.halt()
            return
        }
        val url = args["url"] as? String
        if (url.isNullOrEmpty()) { check(prefs(c).edit().clear().commit()); return }
        val parsed = URL(url)
        check(parsed.protocol == "https" && parsed.userInfo == null && parsed.query == null && parsed.ref == null)
        val access = JSONObject(args["access"] as Map<*, *>)
        val owner = args["owner"] == true
        val until = millis(access.optString("validUntil"))
        check(until > 0) { "Не указан срок доступа" }
        val token = args["token"] as String
        val previous = prefs(c).getString("token", null)
        val encrypted = try { if(previous != null && decrypt(previous) == token) previous else encrypt(token) } catch (_:Exception) { encrypt(token) }
        check(prefs(c).edit().putString("account", account).putString("url", url.trimEnd('/'))
            .putString("token", encrypted).putLong("until", until)
            .putInt("epoch", access.optInt("sessionEpoch")).putBoolean("allowed", allowed(access, owner))
            .putBoolean("share", access.optBoolean("shareLocation")).putBoolean("revoked", false).commit())
    }
    private fun allowed(access: JSONObject, owner: Boolean): Boolean = access.optString("status") == "active" &&
        (owner || ((access.optJSONArray("writable")?.toString()?.contains("\"work\"") == true) &&
            access.optJSONArray("readable")?.toString()?.contains("\"work\"") == true))
    fun permits(c: Context, account: String): Boolean {
        val p = prefs(c)
        if (!p.contains("account")) return true // Local mode has no remote lease.
        return p.getString("account", null) == account && p.getBoolean("allowed", false) &&
            !p.getBoolean("revoked", false) && System.currentTimeMillis() < p.getLong("until", 0)
    }
    fun closed(c: Context, account: String, shift: String): Boolean =
        c.getSharedPreferences("melnitsa_closed_shifts", Context.MODE_PRIVATE)
            .getStringSet(account, emptySet())?.contains(shift) == true
    fun sharing(c: Context): Boolean = prefs(c).contains("account") && prefs(c).getBoolean("share",false)
    private fun invalidate(c: Context, account: String) {
        if (prefs(c).getString("account", null) != account) return
        prefs(c).edit().putBoolean("revoked", true).commit()
        GpsWorker.handler.post { if (GpsGate.account(c, account)) GpsTrackingService.instance?.halt() }
    }
    private fun request(url: String, token: String, body: JSONObject? = null): JSONObject {
        val connection = URL(url).openConnection() as HttpsURLConnection
        try {
            connection.connectTimeout=8000; connection.readTimeout=8000; connection.instanceFollowRedirects=false
            connection.setRequestProperty("Authorization", "Bearer $token")
            if (body != null) {
                connection.requestMethod="POST"; connection.doOutput=true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            }
            val status=connection.responseCode
            if (status == 401 || status == 403) throw SecurityException("revoked")
            check(status in 200..299) { "HTTP $status" }
            val text=connection.inputStream.bufferedReader().use { reader ->
                val buffer=CharArray(4096); val out=StringBuilder()
                while(true) {
                    val n=reader.read(buffer); if(n < 0) break
                    check(out.length+n <= 1024*1024); out.append(buffer,0,n)
                }
                out.toString()
            }
            return if(text.isBlank()) JSONObject() else JSONObject(text)
        } finally { connection.disconnect() }
    }
    /** Called on the GPS queue; network runs on a different executor. */
    fun tick(c: Context, account: String, shift: String, db: GpsDatabase) {
        val p=prefs(c)
        if (p.getString("account",null) != account) return
        val now=android.os.SystemClock.elapsedRealtime()
        if (now-lastRun < 30000 || !busy.compareAndSet(false,true)) return
        lastRun=now
        val url=p.getString("url",null) ?: run { busy.set(false); return }
        val encrypted=p.getString("token",null) ?: run { busy.set(false); return }
        val epoch=p.getInt("epoch",-1)
        val route=try { JSONObject(db.route(account,shift)) } catch (_:Exception) { busy.set(false); return }
        executor.execute {
            try {
                val token=decrypt(encrypted)
                val employee=request("$url/v1/me",token).getJSONObject("employee")
                val access=employee.getJSONObject("access")
                if (employee.getString("id") != account || access.getInt("sessionEpoch") != epoch || !employee.optBoolean("active")) throw SecurityException("revoked")
                // Ignore an in-flight response for a replaced login/token.
                if(p.getString("account",null) != account || p.getString("token",null) != encrypted) return@execute
                val closedRows = employee.optJSONArray("closedShiftIds")
                val closedSet = (0 until (closedRows?.length() ?: 0)).map { closedRows!!.getString(it) }.toSet()
                check(c.getSharedPreferences("melnitsa_closed_shifts",Context.MODE_PRIVATE).edit()
                    .putStringSet(account, closedSet).commit())
                if (closedSet.contains(shift)) {
                    GpsWorker.handler.post { if (GpsGate.account(c,account)) GpsTrackingService.instance?.halt() }
                    return@execute
                }
                val permitted=allowed(access,employee.optBoolean("isOwner"))
                check(p.edit().putLong("until",millis(access.getString("validUntil")))
                    .putBoolean("allowed",permitted).putBoolean("share",access.optBoolean("shareLocation")).commit())
                if(!permitted || !permits(c,account)) { invalidate(c,account); return@execute }
                if(access.optBoolean("shareLocation") && GpsGate.open(c,account,shift)) {
                    val stored = c.getSharedPreferences("FlutterSharedPreferences",Context.MODE_PRIVATE)
                    val envelope = JSONObject(stored.getString("flutter.gazelle_miniapp_sandbox_v2_account_$account", "{}") ?: "{}")
                    val shifts = JSONObject(envelope.optString("journal","{}")).optJSONArray("shifts")
                    val live = (0 until (shifts?.length() ?: 0)).map { shifts!!.getJSONObject(it) }.firstOrNull { it.optString("id") == shift }
                    request("$url/v1/me/telemetry",token,JSONObject().put("shiftId",shift).put("shift",live).put("route",route))
                }
            } catch (_:SecurityException) { if(p.getString("token",null)==encrypted) invalidate(c,account) }
              catch (_:Exception) { /* Durable native route remains available for retry. */ }
            finally { busy.set(false) }
        }
    }
}
