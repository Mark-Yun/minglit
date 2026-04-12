package com.minglit.app_user

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * Dev-flavor MainActivity that registers the [FlutterEngine] in
 * [FlutterEngineCache] so that [QaBugReportReceiver] can obtain a reference
 * to it and invoke MethodChannel calls from a BroadcastReceiver context.
 */
class MainActivity : FlutterActivity() {
    companion object {
        const val ENGINE_CACHE_ID = "minglit_main_engine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put(ENGINE_CACHE_ID, flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        FlutterEngineCache.getInstance().remove(ENGINE_CACHE_ID)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
