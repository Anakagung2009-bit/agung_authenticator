package com.example.agung_auth

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.example.agung_auth.widget.TOTPWidgetProvider
import com.example.agung_auth.passkey.PasskeyHandler

class MainActivity : FlutterFragmentActivity() {
    private val widgetChannel = "com.example.agung_auth/widget"
    private val passkeyChannel = "com.example.agung_auth/passkey"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        Log.d("MainActivity", "updateWidget called")
                        updateWidget()
                        result.success("OK")
                    }
                    "updateWidgetData" -> {
                        val totpData = call.argument<String>("totpData") ?: "[]"
                        Log.d("MainActivity", "updateWidgetData called with: $totpData")
                        updateWidgetData(totpData)
                        result.success("OK")
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
            
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, passkeyChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "startPasskeyLogin") {
                    val fidoData = call.argument<String>("fidoData") ?: ""
                    PasskeyHandler.handlePasskeyLogin(
                        this,
                        fidoData,
                        onSuccess = { result.success(it) },
                        onError = { result.error("PASSKEY_ERROR", it, null) }
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun updateWidget() {
        try {
            val intent = Intent(this, TOTPWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val ids = AppWidgetManager.getInstance(application)
                .getAppWidgetIds(ComponentName(application, TOTPWidgetProvider::class.java))
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            sendBroadcast(intent)
            Log.d("MainActivity", "Widget update broadcast sent")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error updating widget", e)
        }
    }

    private fun updateWidgetData(totpData: String) {
        try {
            val prefs = getSharedPreferences("totp_widget_prefs", Context.MODE_PRIVATE)
            prefs.edit().putString("totp_data", totpData).apply()
            Log.d("MainActivity", "Widget data saved to SharedPreferences")
            updateWidget()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error saving widget data", e)
        }
    }
}
