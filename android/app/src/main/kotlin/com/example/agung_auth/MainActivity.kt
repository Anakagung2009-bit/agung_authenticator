package com.example.agung_auth // sesuaikan dengan package aplikasi Anda

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.agung_auth/widget" // pastikan sesuai dengan di Flutter

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
    }
}
