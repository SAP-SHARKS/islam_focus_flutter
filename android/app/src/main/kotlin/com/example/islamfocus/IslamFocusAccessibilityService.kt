package com.example.islamfocus

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class IslamFocusAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var currentApp: String = ""
    private var allowedApp: String = ""
    private var isOnHomeScreen: Boolean = true
    private val handler = Handler(Looper.getMainLooper())
    private var pendingIntervention: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("islam_focus_prefs", MODE_PRIVATE)

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 200
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: return

        if (!className.contains(".")) return

        // Skip our own app (intervention screen)
        if (packageName == "com.example.islamfocus") {
            return
        }

        // HOME / LAUNCHER - user left the app
        if (isHomeOrLauncher(packageName)) {
            cancelPendingIntervention()
            currentApp = ""
            allowedApp = ""  // CLEAR - next open will trigger intervention
            isOnHomeScreen = true
            prefs.edit().putString("allowed_until_leave", "").apply()
            return
        }

        // System/overlay - skip silently, don't change any state
        if (isSystemOrOverlayPackage(packageName)) {
            return
        }

        // SAME APP - internal navigation (chat switch, comments, share etc)
        if (packageName == currentApp) {
            return
        }

        // ===== USER OPENED A DIFFERENT APP =====
        val previousApp = currentApp
        currentApp = packageName
        isOnHomeScreen = false

        // Check if this app was allowed via "Continue" button
        val savedAllowed = prefs.getString("allowed_until_leave", "") ?: ""
        if (savedAllowed == packageName) {
            allowedApp = packageName
            prefs.edit().putString("allowed_until_leave", "").apply()
            return
        }

        // If this app is currently allowed (user chose Continue and is still using it)
        if (packageName == allowedApp) {
            return
        }

        // User switched to a DIFFERENT app - clear old allowed
        if (previousApp.isNotEmpty() && previousApp != packageName) {
            allowedApp = ""
        }

        // Check if blocked
        val blockedApps = prefs.getStringSet("blocked_apps_set", emptySet()) ?: emptySet()
        if (!blockedApps.contains(packageName)) return

        // DELAY INTERVENTION BY 500ms
        // Prevents false triggers when app is closing
        cancelPendingIntervention()

        val appToBlock = packageName
        pendingIntervention = Runnable {
            if (currentApp == appToBlock && !isOnHomeScreen) {
                launchIntervention(appToBlock)
            }
        }
        handler.postDelayed(pendingIntervention!!, 500)
    }

    private fun cancelPendingIntervention() {
        pendingIntervention?.let { handler.removeCallbacks(it) }
        pendingIntervention = null
    }

    private fun launchIntervention(packageName: String) {
        val mode = prefs.getString("intervention_mode", "standard_dhikr") ?: "standard_dhikr"
        val dhikrText = prefs.getString("dhikr_text", "SubhanAllah") ?: "SubhanAllah"
        val duration = prefs.getInt("dhikr_limit", 10)
        val fillColor = prefs.getString("fill_color", "#1DB954") ?: "#1DB954"

        val intent = Intent(this, InterventionActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_package", packageName)
            putExtra("mode", mode)
            putExtra("dhikr_text", dhikrText)
            putExtra("dhikr_limit", duration)
            putExtra("fill_color", fillColor)
        }
        startActivity(intent)
    }

    private fun isSystemOrOverlayPackage(packageName: String): Boolean {
        return packageName == "com.android.systemui" ||
               packageName == "android" ||
               packageName == "com.android.settings" ||
               packageName == "com.android.packageinstaller" ||
               packageName == "com.google.android.permissioncontroller" ||
               packageName == "com.android.documentsui" ||
               packageName.contains("systemui") ||
               packageName.contains("camera") ||
               packageName.contains("gallery") ||
               packageName.contains("photos") ||
               packageName.contains("media") ||
               packageName.contains("webview") ||
               packageName.contains("screenshot") ||
               packageName.contains("screencapture") ||
               packageName.contains("screen_capture") ||
               packageName.contains("screenrecord") ||
               packageName.contains("keyboard") ||
               packageName.contains("inputmethod") ||
               packageName.contains("gboard") ||
               packageName.contains("swiftkey") ||
               packageName.contains("notification") ||
               packageName.contains("quicksetting") ||
               packageName.contains("overlay") ||
               packageName.contains("permission") ||
               packageName.contains("packageinstaller") ||
               packageName.contains("dialer") ||
               packageName.contains("incallui") ||
               packageName.contains("telecom") ||
               packageName.contains("clipboard") ||
               packageName.contains("content") ||
               packageName.contains("transsion") ||
               packageName.contains("xos") ||
               packageName.contains("samsung.android.app.cocktail") ||
               packageName.contains("samsung.android.app.edge") ||
               packageName == "com.google.android.gms" ||
               packageName == "com.google.android.gsf" ||
               packageName == "com.android.providers.settings" ||
               packageName == "com.android.shell" ||
               packageName == "com.android.vending"
    }

    private fun isHomeOrLauncher(packageName: String): Boolean {
        return packageName == "com.android.launcher" ||
               packageName == "com.android.launcher3" ||
               packageName.contains("launcher") ||
               packageName.contains("home") ||
               packageName == "com.transsion.XOSLauncher" ||
               packageName == "com.mi.android.globallauncher" ||
               packageName == "com.sec.android.app.launcher" ||
               packageName == "com.huawei.android.launcher" ||
               packageName == "com.oppo.launcher" ||
               packageName == "com.realme.launcher" ||
               packageName == "com.nothing.launcher" ||
               packageName == "com.google.android.apps.nexuslauncher"
    }

    override fun onInterrupt() {}
}