package com.example.portal_data

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "portal_data/app_package_info"
        ).setMethodCallHandler { call, result ->
            if (call.method != "getAppPackageInfo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val packageManager = applicationContext.packageManager
                val packageName = applicationContext.packageName
                val packageInfo = packageManager.getPackageInfo(packageName, 0)

                val buildNumber = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode.toString()
                } else {
                    @Suppress("DEPRECATION")
                    packageInfo.versionCode.toString()
                }

                result.success(
                    mapOf(
                        "version" to (packageInfo.versionName ?: ""),
                        "buildNumber" to buildNumber,
                    )
                )
            } catch (exception: Exception) {
                result.error(
                    "PACKAGE_INFO_ERROR",
                    exception.message,
                    null,
                )
            }
        }
    }
}
