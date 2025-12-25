package com.example.personal_news_brief

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.ShareCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "personal_news_brief/platform"
    private val NOTIFICATION_CHANNEL_ID = "personal_news_brief_notifications"
    private val NOTIFICATION_CHANNEL_NAME = "Personal News Brief Notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "openUrl" -> {
                    try {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            openUrl(url)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "URL不能为空", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "shareText" -> {
                    try {
                        val title = call.argument<String>("title") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        shareText(title, text)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "canOpenUrl" -> {
                    try {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            val canOpen = canOpenUrl(url)
                            result.success(canOpen)
                        } else {
                            result.error("INVALID_ARGUMENT", "URL不能为空", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getAppInfo" -> {
                    try {
                        val appInfo = getAppInfo()
                        result.success(appInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "createShortcut" -> {
                    try {
                        val id = call.argument<String>("id") ?: ""
                        val shortLabel = call.argument<String>("shortLabel") ?: ""
                        val longLabel = call.argument<String>("longLabel") ?: ""
                        createShortcut(id, shortLabel, longLabel)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "hasNotificationPermission" -> {
                    try {
                        val hasPermission = hasNotificationPermission()
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "requestNotificationPermission" -> {
                    try {
                        val hasPermission = requestNotificationPermission()
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "showNotification" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val title = call.argument<String>("title") ?: ""
                        val content = call.argument<String>("content") ?: ""
                        val payload = call.argument<String>("payload")
                        showNotification(id, title, content, payload)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getDeviceInfo" -> {
                    try {
                        val deviceInfo = getDeviceInfo()
                        result.success(deviceInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isNetworkConnected" -> {
                    try {
                        val isConnected = isNetworkConnected()
                        result.success(isConnected)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 创建通知渠道
        createNotificationChannel()
    }

    private fun openUrl(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun shareText(title: String, text: String) {
        val intent = ShareCompat.IntentBuilder(this)
            .setType("text/plain")
            .setChooserTitle(title)
            .setText(text)
            .createChooserIntent()
        startActivity(intent)
    }

    private fun canOpenUrl(url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        val packageManager = packageManager
        val activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return activities.isNotEmpty()
    }

    private fun getAppInfo(): Map<String, String> {
        val packageManager = packageManager
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        
        return mapOf(
            "appName" to packageInfo.applicationInfo.loadLabel(packageManager).toString(),
            "packageName" to packageName,
            "versionName" to packageInfo.versionName,
            "versionCode" to packageInfo.longVersionCode.toString(),
            "buildNumber" to packageInfo.longVersionCode.toString()
        )
    }

    private fun createShortcut(id: String, shortLabel: String, longLabel: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            val shortcutManager = getSystemService(Context.SHORTCUT_SERVICE) as ShortcutManager
            
            val intent = Intent(this, MainActivity::class.java)
            intent.action = Intent.ACTION_VIEW
            intent.putExtra("shortcut_id", id)
            
            val shortcut = ShortcutInfo.Builder(this, id)
                .setShortLabel(shortLabel)
                .setLongLabel(longLabel)
                .setIcon(Icon.createWithResource(this, R.drawable.ic_launcher_foreground))
                .setIntent(intent)
                .build()
                
            shortcutManager.addDynamicShortcuts(listOf(shortcut))
        }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Android 13以下不需要权限
        }
    }

    private fun requestNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (!hasNotificationPermission()) {
                // 在实际应用中，这里应该启动权限请求对话框
                // 由于这是方法调用，我们返回false表示没有权限
                false
            } else {
                true
            }
        } else {
            true
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Personal News Brief应用的通知"
                enableLights(true)
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(id: Int, title: String, content: String, payload: String?) {
        val intent = Intent(this, MainActivity::class.java)
        if (payload != null) {
            intent.putExtra("notification_payload", payload)
        }
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
            
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(id, notification)
    }

    private fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "manufacturer" to android.os.Build.MANUFACTURER,
            "model" to android.os.Build.MODEL,
            "androidVersion" to android.os.Build.VERSION.RELEASE,
            "sdkVersion" to android.os.Build.VERSION.SDK_INT.toString(),
            "brand" to android.os.Build.BRAND,
            "product" to android.os.Build.PRODUCT,
            "device" to android.os.Build.DEVICE
        )
    }

    private fun isNetworkConnected(): Boolean {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
        val activeNetwork = connectivityManager.activeNetworkInfo
        return activeNetwork?.isConnectedOrConnecting == true
    }
}