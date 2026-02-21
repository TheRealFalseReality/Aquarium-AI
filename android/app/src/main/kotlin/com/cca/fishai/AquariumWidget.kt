package com.cca.fishai

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * AppWidgetProvider for the Aquarium AI home screen widget.
 *
 * Displays tank info (name, type, size, inhabitants count, and next notification)
 * for the tank selected by the user. Data is written from Flutter via [HomeWidgetPlugin].
 */
class AquariumWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        private const val TANK_TYPE_FRESHWATER = "freshwater"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val tankName = widgetData.getString("widget_tank_name", null)
                ?: context.getString(R.string.widget_default_tank_name)
            val tankType = widgetData.getString("widget_tank_type", "")
            val tankSize = widgetData.getString("widget_tank_size", "")
            val inhabitantsCount = widgetData.getString("widget_inhabitants_count", "")
            val nextNotification = widgetData.getString("widget_next_notification", "")

            val views = RemoteViews(context.packageName, R.layout.aquarium_widget)

            views.setTextViewText(R.id.widget_tank_name, tankName)
            views.setTextViewText(R.id.widget_tank_type, tankType)
            views.setTextViewText(R.id.widget_tank_size, tankSize)
            views.setTextViewText(R.id.widget_inhabitants_count, inhabitantsCount)
            views.setTextViewText(R.id.widget_next_notification, nextNotification)

            // Set tank type icon
            val iconRes = if (tankType.equals(TANK_TYPE_FRESHWATER, ignoreCase = true))
                android.R.drawable.ic_menu_compass
            else
                android.R.drawable.ic_menu_mapmode
            views.setImageViewResource(R.id.widget_icon, iconRes)

            // Tap on widget opens the app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                data = Uri.parse("aquariumai://widget/tank")
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
