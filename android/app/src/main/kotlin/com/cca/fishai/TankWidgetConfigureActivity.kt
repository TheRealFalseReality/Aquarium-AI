package com.cca.fishai

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/**
 * Configuration activity shown when the user places an Aquarium AI widget on their home screen.
 *
 * Reads the list of configured tanks from Flutter's SharedPreferences, presents a picker
 * dialog, then saves the selected tank's data via [HomeWidgetPlugin] and triggers a widget
 * refresh before finishing with [RESULT_OK].
 *
 * If no tanks exist yet, the main app is launched so the user can create one.
 */
class TankWidgetConfigureActivity : Activity() {

    companion object {
        /** SharedPreferences file name used by Flutter's shared_preferences plugin. */
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"

        /** Key under which the tank JSON array is persisted by the Flutter app. */
        private const val TANKS_KEY = "flutter.user_tanks"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Return CANCELED by default so the widget is not placed if the user backs out.
        setResult(RESULT_CANCELED)

        appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val tanks = readTanks()
        if (tanks.isEmpty()) {
            // No tanks configured yet — open the app so the user can add one.
            packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
            finish()
            return
        }

        showTankPicker(tanks)
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /** Reads and parses the tank list stored by the Flutter app. */
    private fun readTanks(): List<JSONObject> {
        return try {
            val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val json = prefs.getString(TANKS_KEY, null) ?: return emptyList()
            val array = JSONArray(json)
            List(array.length()) { array.getJSONObject(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Shows a dialog listing all configured tanks. */
    private fun showTankPicker(tanks: List<JSONObject>) {
        val names = tanks.map { it.optString("name", "Unknown Tank") }.toTypedArray()

        AlertDialog.Builder(this)
            .setTitle(getString(R.string.widget_select_tank_title))
            .setItems(names) { _, index -> onTankSelected(tanks[index]) }
            .setNegativeButton(android.R.string.cancel) { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .show()
    }

    /** Persists the chosen tank's data and updates the widget. */
    private fun onTankSelected(tank: JSONObject) {
        val name = tank.optString("name", "")
        val type = tank.optString("type", "")
        val sizeGallons = tank.optDoubleOrNull("sizeGallons")
        val sizeLiters = tank.optDoubleOrNull("sizeLiters")
        val inhabitants = tank.optJSONArray("inhabitants") ?: JSONArray()
        val notifications = tank.optJSONArray("notifications") ?: JSONArray()

        HomeWidgetPlugin.getData(this).edit()
            .putString("widget_tank_name", name)
            .putString("widget_tank_type", type)
            .putString("widget_tank_size", formatSize(sizeGallons, sizeLiters))
            .putString("widget_inhabitants_count", formatInhabitants(inhabitants))
            .putString("widget_next_notification", formatNextNotification(notifications))
            .apply()

        val appWidgetManager = AppWidgetManager.getInstance(this)
        AquariumWidget.updateAppWidget(this, appWidgetManager, appWidgetId)

        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
        finish()
    }

    // -------------------------------------------------------------------------
    // Formatting helpers (mirror of WidgetService in Dart)
    // -------------------------------------------------------------------------

    private fun formatSize(gallons: Double?, liters: Double?): String = when {
        gallons != null && liters != null -> "${gallons.toInt()} gal / ${liters.toInt()} L"
        gallons != null -> "${gallons.toInt()} gal"
        liters != null -> "${liters.toInt()} L"
        else -> ""
    }

    private fun formatInhabitants(inhabitants: JSONArray): String {
        val count = (0 until inhabitants.length())
            .sumOf { inhabitants.getJSONObject(it).optInt("quantity", 0) }
        return if (count == 0) "" else "$count inhabitant${if (count == 1) "" else "s"}"
    }

    private fun formatNextNotification(notifications: JSONArray): String {
        val now = System.currentTimeMillis()
        data class Upcoming(val timeMs: Long, val title: String)

        val next = (0 until notifications.length())
            .mapNotNull { i ->
                val n = notifications.getJSONObject(i)
                if (!n.optBoolean("enabled", true)) return@mapNotNull null
                val dateStr = n.optString("scheduledNextDate")
                    .takeIf { it.isNotEmpty() && it != "null" } ?: return@mapNotNull null
                try {
                    val millis = parseIso8601(dateStr)
                    if (millis <= now) return@mapNotNull null
                    val title = n.optString("customTitle").takeIf { it.isNotEmpty() }
                        ?: n.optString("type", "Reminder")
                            .replaceFirstChar { it.uppercaseChar() }
                    Upcoming(millis, title)
                } catch (e: Exception) {
                    null
                }
            }
            .minByOrNull { it.timeMs } ?: return ""

        val diff = next.timeMs - now
        val days = diff / 86_400_000L
        val hours = diff / 3_600_000L
        val mins = diff / 60_000L
        return when {
            days > 0 -> "⏰ ${next.title} in ${days}d"
            hours > 0 -> "⏰ ${next.title} in ${hours}h"
            mins > 0 -> "⏰ ${next.title} in ${mins}m"
            else -> ""
        }
    }

    /** ISO-8601 parser that works down to API 21 without java.time.
     *
     * Flutter's [DateTime.toIso8601String] produces either no timezone suffix (local)
     * or a 'Z' suffix (UTC). Both positive (+HH:mm) and negative (-HH:mm) offset forms
     * are handled defensively. A new [SimpleDateFormat] is created on each call because
     * the class is not thread-safe.
     */
    private fun parseIso8601(s: String): Long {
        // Strip sub-second precision then any timezone indicator (Z or ±HH:mm).
        val noMillis = s.substringBefore(".")
        val clean = noMillis
            .replace(Regex("[+-]\\d{2}:\\d{2}$"), "")
            .trimEnd('Z')
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.parse(clean)?.time ?: throw IllegalArgumentException("Cannot parse: $s")
    }

    /** Returns a Double from this JSONObject or null if the key is absent/null/NaN. */
    private fun JSONObject.optDoubleOrNull(key: String): Double? {
        if (isNull(key)) return null
        val v = optDouble(key)
        return if (v.isNaN()) null else v
    }
}
