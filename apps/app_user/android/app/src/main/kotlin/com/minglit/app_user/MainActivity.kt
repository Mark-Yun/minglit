package com.minglit.app_user

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

// Fix #1322: dev-flavor에서만 쓰이지만 src/dev 분리 시 Redeclaration — src/main에 통합
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
