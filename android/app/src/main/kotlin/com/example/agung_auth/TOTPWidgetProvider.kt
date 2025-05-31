package com.example.agung_auth

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.content.SharedPreferences
import android.util.Log

class TOTPWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d("TOTPWidgetProvider", "onUpdate dipanggil untuk ${appWidgetIds.size} widget")
        
        // Update setiap widget
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        // Ambil data TOTP dari SharedPreferences
        val prefs = context.getSharedPreferences("totp_prefs", Context.MODE_PRIVATE)
        val totpCode1 = prefs.getString("totp_code_1", "Tidak ada kode") ?: "Tidak ada kode"
        val totpCode2 = prefs.getString("totp_code_2", "Tidak ada kode") ?: "Tidak ada kode"
        
        // Buat tampilan widget
        val views = RemoteViews(context.packageName, R.layout.totp_widget_layout)
        views.setTextViewText(R.id.totp_code_text_1, totpCode1)
        views.setTextViewText(R.id.totp_code_text_2, totpCode2)
        
        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d("TOTPWidgetProvider", "Widget $appWidgetId diupdate dengan kode: $totpCode1, $totpCode2")
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d("TOTPWidgetProvider", "onReceive: ${intent.action}")
        
        // Tambahkan logika khusus jika diperlukan
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
            
            if (appWidgetIds != null) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }
}