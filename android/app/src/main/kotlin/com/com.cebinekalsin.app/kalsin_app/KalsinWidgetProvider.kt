package com.cebinekalsin.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class KalsinWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.kalsin_widget_layout)

            // Read data from SharedPreferences (set by Flutter side)
            val totalAmount = prefs.getString("total_amount", "₺0") ?: "₺0"
            val todayAmount = prefs.getString("today_amount", "Bugün: ₺0") ?: "Bugün: ₺0"
            val streakText = prefs.getString("streak_text", "🔥 0 gün") ?: "🔥 0 gün"
            val goalEmoji = prefs.getString("goal_emoji", "🎯") ?: "🎯"
            val goalTitle = prefs.getString("goal_title", "Hedef belirle") ?: "Hedef belirle"
            val goalPercent = prefs.getString("goal_percent", "%0") ?: "%0"
            val goalProgressStr = prefs.getString("goal_progress", "0.0") ?: "0.0"
            val goalProgress = goalProgressStr.toFloatOrNull() ?: 0f

            // Set text values
            views.setTextViewText(R.id.total_amount, totalAmount)
            views.setTextViewText(R.id.today_text, todayAmount)
            views.setTextViewText(R.id.streak_text, streakText)
            views.setTextViewText(R.id.goal_emoji, goalEmoji)
            views.setTextViewText(R.id.goal_title, goalTitle)
            views.setTextViewText(R.id.goal_percent, goalPercent)

            // Progress bar (0-100)
            val progressInt = (goalProgress * 100).toInt().coerceIn(0, 100)
            views.setProgressBar(R.id.goal_progress_bar, 100, progressInt, false)

            // Click to open app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
