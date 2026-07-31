package com.mstech.corecare

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.mstech.corecare/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHealthConnect" -> {
                        val opened = openHealthConnect()
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Try to open the Health Connect app's settings screen so the user can
     * inspect connected apps & permissions.
     *
     * Strategy (tries each in order until one works):
     *  1. Android 14+ system Health Connect settings activity
     *  2. The Health Connect APK ("com.google.android.apps.healthdata")
     *     launcher intent
     *  3. Play Store page for Health Connect (graceful fallback)
     */
    private fun openHealthConnect(): Boolean {
        // 1. Android 14+ — settings panel exposed by the platform itself
        runCatching {
            val intent = Intent("android.health.connect.action.HEALTH_HOME_SETTINGS")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        }

        // 2. Pre-14 — open the Health Connect APK directly
        runCatching {
            val pm = packageManager
            val launchIntent = pm.getLaunchIntentForPackage(
                "com.google.android.apps.healthdata"
            )
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                return true
            }
        }

        // 3. Last resort — Play Store listing
        runCatching {
            val playIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("market://details?id=com.google.android.apps.healthdata"),
            )
            playIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(playIntent)
            return true
        }.recoverCatching {
            val webIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse(
                    "https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata"
                ),
            )
            webIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(webIntent)
            return true
        }.recoverCatching {
            // Swallow ActivityNotFoundException etc.
            if (it is ActivityNotFoundException) Unit else throw it
        }

        return false
    }
}
