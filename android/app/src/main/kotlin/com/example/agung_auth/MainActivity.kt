package com.example.agung_auth

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
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
                if (call.method == "updateWidget") {
                    val intent = Intent(this, TOTPWidgetProvider::class.java)
                    intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    val ids = AppWidgetManager.getInstance(application)
                        .getAppWidgetIds(ComponentName(application, TOTPWidgetProvider::class.java))
                    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    sendBroadcast(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
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
}
