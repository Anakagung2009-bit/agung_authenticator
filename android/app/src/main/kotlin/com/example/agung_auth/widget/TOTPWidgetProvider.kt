package com.example.agung_auth.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.agung_auth.R

class TOTPWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.totp_widget)
            views.setTextViewText(R.id.widget_text, "Updated from Flutter!")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
