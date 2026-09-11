package com.previewport.app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.previewport/device_info"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceInfo") {
                val model = Build.MODEL ?: "Unknown"
                val manufacturer = Build.MANUFACTURER ?: "Unknown"
                val osVersion = Build.VERSION.RELEASE ?: "Unknown"

                // Capitalize manufacturer for display (e.g. "samsung" → "Samsung")
                val displayName = if (model.startsWith(manufacturer, ignoreCase = true)) {
                    model
                } else {
                    "${manufacturer.replaceFirstChar { it.uppercaseChar() }} $model"
                }

                result.success(
                    mapOf(
                        "model" to displayName,
                        "identifier" to "${Build.MANUFACTURER}/${Build.DEVICE}",
                        "osVersion" to osVersion,
                        "platform" to "android",
                    )
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
