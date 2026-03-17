package com.example.islamfocus

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.*

class MainActivity : FlutterActivity() {
    private val USAGE_CHANNEL = "com.example.islamfocus/usage_stats"
    private val BLOCKING_CHANNEL = "com.islamfocus.app/blocking"
    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prefs = getSharedPreferences("islam_focus_prefs", MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isUsageStatsGranted" -> result.success(isUsageStatsGranted())
                "requestUsageStats" -> { requestUsageStats(); result.success(null) }
                "isAccessibilityServiceEnabled" -> result.success(isAnyAccessibilityServiceEnabled())
                "requestAccessibility" -> { requestAccessibility(); result.success(null) }
                "getAppUsageStats" -> {
                    val days = call.argument<Int>("days") ?: 1
                    result.success(getAppUsageStats(days))
                }
                "getAppIcon" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    result.success(getAppIconBase64(pkg))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCKING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> result.success(getInstalledApps())
                "updateBlockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    prefs.edit().putStringSet("blocked_apps_set", packages.toSet()).apply()
                    result.success(null)
                }
                "updateSettings" -> {
                    val editor = prefs.edit()
                    call.argument<String>("mode")?.let { editor.putString("intervention_mode", it) }
                    call.argument<String>("dhikrText")?.let { editor.putString("dhikr_text", it) }
                    call.argument<Int>("breathingDurationSeconds")?.let { editor.putInt("dhikr_limit", it) }
                    call.argument<String>("fillColor")?.let { editor.putString("fill_color", it) }
                    call.argument<Boolean>("reInterventionEnabled")?.let { editor.putBoolean("re_intervention_enabled", it) }
                    call.argument<Int>("reInterventionMinutes")?.let { editor.putInt("re_intervention_minutes", it) }
                    editor.apply()
                    result.success(null)
                }
                "isAccessibilityEnabled" -> result.success(isAnyAccessibilityServiceEnabled())
                "isUsagePermissionEnabled" -> result.success(isUsageStatsGranted())
                "openAccessibilitySettings" -> { requestAccessibility(); result.success(null) }
                "openUsageAccessSettings" -> { requestUsageStats(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    private fun getAppIconBase64(packageName: String): String? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val bmp = Bitmap.createBitmap(48, 48, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, 48, 48)
                drawable.draw(canvas)
                bmp
            }
            val scaled = Bitmap.createScaledBitmap(bitmap, 48, 48, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 90, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun isUsageStatsGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        return appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName) == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStats() { startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)) }

    private fun isAnyAccessibilityServiceEnabled(): Boolean {
        val services = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
        return services.contains("$packageName/")
    }

    private fun requestAccessibility() { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }

    private fun getAppUsageStats(days: Int): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = Calendar.getInstance()
        val endTime = cal.timeInMillis
        cal.add(Calendar.DAY_OF_YEAR, -days)
        val startTime = cal.timeInMillis

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val blockedApps = prefs.getStringSet("blocked_apps_set", emptySet()) ?: emptySet()

        val result = mutableListOf<Map<String, Any>>()
        val packageTotals = mutableMapOf<String, Long>()

        for (stat in stats) {
            val pkg = stat.packageName
            val time = stat.totalTimeInForeground
            if (time > 0) {
                packageTotals[pkg] = (packageTotals[pkg] ?: 0) + time
            }
        }

        for ((pkg, totalTime) in packageTotals) {
            val appName = try {
                val appInfo = packageManager.getApplicationInfo(pkg, 0)
                packageManager.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) { pkg }

            result.add(mapOf(
                "packageName" to pkg,
                "appName" to appName,
                "totalTimeMs" to totalTime,
                "isBlocked" to blockedApps.contains(pkg)
            ))
        }

        result.sortByDescending { it["totalTimeMs"] as Long }
        return result
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val addedPackages = mutableSetOf<String>()
        val result = mutableListOf<Map<String, Any>>()

        val hiddenPackages = setOf(
            "com.example.islamfocus",
            "com.android.settings",
            "com.android.vending",
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.android.providers.settings",
            "com.android.shell",
            "com.android.systemui"
        )

        val mainIntent = Intent(Intent.ACTION_MAIN, null).addCategory(Intent.CATEGORY_LAUNCHER)
        val launchableApps: List<ResolveInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(mainIntent, 0)
        }

        for (resolveInfo in launchableApps) {
            val pkg = resolveInfo.activityInfo.packageName
            if (pkg in hiddenPackages || pkg in addedPackages) continue
            addedPackages.add(pkg)

            val appName = try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) { pkg }

            result.add(mapOf("packageName" to pkg, "appName" to appName, "isSystemApp" to false))
        }

        if (isUsageStatsGranted()) {
            try {
                val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val cal = Calendar.getInstance()
                val endTime = cal.timeInMillis
                cal.add(Calendar.DAY_OF_YEAR, -30)
                val startTime = cal.timeInMillis

                val usageStats = usm.queryUsageStats(UsageStatsManager.INTERVAL_MONTHLY, startTime, endTime)
                for (stat in usageStats) {
                    val pkg = stat.packageName
                    if (pkg in hiddenPackages || pkg in addedPackages) continue
                    if (stat.totalTimeInForeground < 60000) continue

                    val appName = try {
                        val appInfo = pm.getApplicationInfo(pkg, 0)
                        pm.getApplicationLabel(appInfo).toString()
                    } catch (e: Exception) { continue }

                    val launchIntent = pm.getLaunchIntentForPackage(pkg)
                    if (launchIntent != null) {
                        addedPackages.add(pkg)
                        result.add(mapOf("packageName" to pkg, "appName" to appName, "isSystemApp" to false))
                    }
                }
            } catch (e: Exception) {}
        }

        val allApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

        for (appInfo in allApps) {
            val pkg = appInfo.packageName
            if (pkg in hiddenPackages || pkg in addedPackages) continue

            val launchIntent = pm.getLaunchIntentForPackage(pkg)
            if (launchIntent != null) {
                addedPackages.add(pkg)
                val appName = try {
                    pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) { pkg }

                result.add(mapOf("packageName" to pkg, "appName" to appName, "isSystemApp" to false))
            }
        }

        result.sortBy { (it["appName"] as String).lowercase() }
        return result
    }
}