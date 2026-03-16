package com.example.scam_radar

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.example.scam_radar/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Dart asks on startup: was the app opened via share?
                    "getSharedText" -> {
                        val text = intent
                            ?.takeIf { it.action == Intent.ACTION_SEND && it.type == "text/plain" }
                            ?.getStringExtra(Intent.EXTRA_TEXT)
                        result.success(text)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Fires when the app is already running and another share arrives.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, channel).invokeMethod("sharedText", text)
            }
        }
    }
}
