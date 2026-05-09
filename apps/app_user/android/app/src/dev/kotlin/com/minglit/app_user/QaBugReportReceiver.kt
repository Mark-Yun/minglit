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
 * # Bug report (default — creates GitHub issue + uploads to Supabase):
 * adb shell am broadcast \
 *   -a com.minglit.dev.QA_BUG_REPORT \
 *   -n com.minglit.app_user.dev/.QaBugReportReceiver \
 *   --es title "Bug title" \
 *   --es description "Bug description" \
 *   --es scenario_id "U-S04" \
 *   --es session_id "20260412-173833"
 *
 * # Spec-walk capture (no issue, no Supabase, save to device):
 * adb shell am broadcast \
 *   -a com.minglit.dev.QA_BUG_REPORT \
 *   -n com.minglit.app_user.dev/.QaBugReportReceiver \
 *   --es title "home_page" \
 *   --ez file_issue false \
 *   --ez upload_to_supabase false \
 *   --es artifact_dir "/sdcard/qa/walk-001/home_page"
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
        val fileIssue = intent.getBooleanExtra("file_issue", true)
        val uploadToSupabase = intent.getBooleanExtra("upload_to_supabase", true)
        val artifactDir = intent.getStringExtra("artifact_dir") ?: ""
        val includeDump = intent.getBooleanExtra("include_dump", true)

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
                "file_issue" to fileIssue,
                "upload_to_supabase" to uploadToSupabase,
                "artifact_dir" to artifactDir,
                "include_dump" to includeDump,
            ),
        )
    }
}
