package com.minglit.app_user

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Dev-only BroadcastReceiver that forwards ADB-triggered bug report intents
 * to Flutter via MethodChannel.
 *
 * Usage from ADB:
 * ```
 * adb shell am broadcast \
 *   -a com.minglit.dev.QA_BUG_REPORT \
 *   --es title "Bug title" \
 *   --es description "Bug description" \
 *   --es scenario_id "U-S04" \
 *   --es session_id "20260412-173833"
 * ```
 *
 * The Flutter engine must be running (app in foreground) for the channel
 * call to reach Dart. If the engine is not available the broadcast is
 * silently ignored.
 */
class QaBugReportReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "QA Bug Report"
        val description = intent.getStringExtra("description") ?: ""
        val scenarioId = intent.getStringExtra("scenario_id") ?: ""
        val sessionId = intent.getStringExtra("session_id") ?: ""

        val engine = FlutterEngineCache.getInstance()
            .get(MainActivity.ENGINE_CACHE_ID) ?: return

        val channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "com.minglit.dev/qa_bug_report",
        )
        channel.invokeMethod(
            "triggerBugReport",
            mapOf(
                "title" to title,
                "description" to description,
                "scenario_id" to scenarioId,
                "session_id" to sessionId,
            ),
        )
    }
}
