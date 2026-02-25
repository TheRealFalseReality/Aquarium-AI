package com.cca.fishai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Android home screen widget that lists configured aquarium tanks with basic stats.
 * Data is provided by the Flutter app via the home_widget package.
 */
class AquariumWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val tanksJson = widgetData.getString("widget_tanks", null)

            val views = RemoteViews(context.packageName, R.layout.aquarium_widget)

            // Tapping the widget opens the app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            val tankRowIds = listOf(
                Triple(R.id.tank_row_1, R.id.tank_name_1, R.id.tank_stats_1),
                Triple(R.id.tank_row_2, R.id.tank_name_2, R.id.tank_stats_2),
                Triple(R.id.tank_row_3, R.id.tank_name_3, R.id.tank_stats_3)
            )

            if (!tanksJson.isNullOrEmpty()) {
                try {
                    val tanksArray = JSONArray(tanksJson)
                    val tankCount = tanksArray.length()

                    views.setTextViewText(
                        R.id.widget_tank_count,
                        "$tankCount tank${if (tankCount != 1) "s" else ""}"
                    )

                    for (i in tankRowIds.indices) {
                        val (rowId, nameId, statsId) = tankRowIds[i]
                        if (i < tankCount) {
                            val tank = tanksArray.getJSONObject(i)
                            val name = tank.optString("name", "Tank ${i + 1}")
                            val type = tank.optString("type", "freshwater")
                            val inhabitants = tank.optInt("inhabitants", 0)
                            val sizeGallons = tank.optDouble("sizeGallons", Double.NaN)
                            val latestParam = tank.optString("latestParam", "")
                            val latestParamValue = tank.optDouble("latestParamValue", Double.NaN)
                            val latestParamUnit = tank.optString("latestParamUnit", "")

                            val typeLabel = if (type == "marine") "Marine" else "Freshwater"
                            val sizeStr = if (!sizeGallons.isNaN()) " \u00b7 ${sizeGallons.toInt()} gal" else ""
                            val fishStr = "$inhabitants fish"
                            val paramStr = if (latestParam.isNotEmpty() && !latestParamValue.isNaN()) {
                                val unitSuffix = if (latestParamUnit.isNotEmpty()) " $latestParamUnit" else ""
                                " \u00b7 $latestParam: ${"%.1f".format(latestParamValue)}$unitSuffix"
                            } else ""
                            val stats = "$typeLabel$sizeStr \u00b7 $fishStr$paramStr"

                            views.setViewVisibility(rowId, View.VISIBLE)
                            views.setTextViewText(nameId, name)
                            views.setTextViewText(statsId, stats)
                        } else {
                            views.setViewVisibility(rowId, View.GONE)
                        }
                    }

                    if (tankCount > 3) {
                        views.setViewVisibility(R.id.widget_more_tanks, View.VISIBLE)
                        views.setTextViewText(R.id.widget_more_tanks, "+${tankCount - 3} more")
                    } else {
                        views.setViewVisibility(R.id.widget_more_tanks, View.GONE)
                    }

                    views.setViewVisibility(
                        R.id.widget_no_tanks,
                        if (tankCount == 0) View.VISIBLE else View.GONE
                    )
                } catch (e: Exception) {
                    showEmptyState(views, tankRowIds)
                }
            } else {
                showEmptyState(views, tankRowIds)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun showEmptyState(
            views: RemoteViews,
            tankRowIds: List<Triple<Int, Int, Int>>
        ) {
            views.setTextViewText(R.id.widget_tank_count, "0 tanks")
            for (row in tankRowIds) {
                views.setViewVisibility(row.first, View.GONE)
            }
            views.setViewVisibility(R.id.widget_more_tanks, View.GONE)
            views.setViewVisibility(R.id.widget_no_tanks, View.VISIBLE)
        }
    }
}
