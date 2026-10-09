package com.gazelle.gazelle_android

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class UpdateFileProvider : FileProvider()

/** Only exposes the private update cache, never employee data. */
class AppUpdateBridge(private val activity: Activity) {
    private val apk: File get() = File(File(activity.cacheDir, "app_updates").apply { mkdirs() }, "app-release.apk")
    private var verifying = false
    @Suppress("DEPRECATION")
    private fun code(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): Set<String> {
        val values = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        return values?.map { signature ->
            MessageDigest.getInstance("SHA-256").digest(signature.toByteArray()).joinToString("") { "%02x".format(it) }
        }?.toSet() ?: emptySet()
    }
    @Suppress("DEPRECATION")
    fun handle(method: String, args: Map<*, *>, result: MethodChannel.Result) {
        try {
            when (method) {
                "info" -> {
                    val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    result.success(mapOf("versionCode" to code(info), "versionName" to info.versionName, "apkPath" to apk.absolutePath))
                }
                "permission" -> {
                    if (Build.VERSION.SDK_INT >= 26) activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "install" -> {
                    if (verifying) { result.error("busy", "APK уже проверяется.", null); return }
                    val expectedHash = args["sha256"] as? String ?: error("Нет контрольной суммы.")
                    val expectedCode = (args["versionCode"] as? Number)?.toLong() ?: error("Нет номера версии.")
                    verifying = true
                    Thread {
                        try {
                            val file = apk
                            require(file.isFile) { "APK отсутствует. Загрузите обновление заново." }
                            val hash = MessageDigest.getInstance("SHA-256")
                            file.inputStream().use { input ->
                                val buffer = ByteArray(65536)
                                while (true) { val count = input.read(buffer); if (count < 0) break; hash.update(buffer, 0, count) }
                            }
                            require(hash.digest().joinToString("") { "%02x".format(it) } == expectedHash) { "Контрольная сумма APK не совпадает." }
                            val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
                            val pm = activity.packageManager
                            val installed = pm.getPackageInfo(activity.packageName, flags)
                            val incoming = pm.getPackageArchiveInfo(file.absolutePath, flags) ?: error("Повреждённый APK.")
                            require(incoming.packageName == activity.packageName) { "APK относится к другому приложению." }
                            require(code(incoming) == expectedCode && expectedCode > code(installed)) { "Номер версии APK не подходит." }
                            if (Build.VERSION.SDK_INT >= 24) {
                                require((incoming.applicationInfo?.minSdkVersion ?: Int.MAX_VALUE) <= Build.VERSION.SDK_INT) { "Для обновления нужна более новая версия Android." }
                            }
                            val currentSigners = signers(installed)
                            require(currentSigners.isNotEmpty() && currentSigners == signers(incoming)) { "Подпись APK отличается от установленного приложения. Нужна сборка с тем же ключом." }
                            activity.runOnUiThread {
                                try {
                                    check(!activity.isFinishing && !activity.isDestroyed) { "Экран закрыт." }
                                    if (Build.VERSION.SDK_INT >= 26 && !pm.canRequestPackageInstalls()) {
                                        result.success("permission")
                                    } else {
                                        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
                                        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                                            setDataAndType(uri, "application/vnd.android.package-archive")
                                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        })
                                        result.success("installer")
                                    }
                                } catch (e: Exception) { result.error("install_failed", e.message ?: "Не удалось открыть установщик.", null) }
                                finally { verifying = false }
                            }
                        } catch (e: Exception) {
                            activity.runOnUiThread { verifying = false; result.error("invalid_apk", e.message ?: "APK не прошёл проверку.", null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) { result.error("update_failed", e.message ?: "Ошибка обновления.", null) }
    }
}
