package com.salate.browser

import android.os.Build
import android.os.Bundle
import android.app.role.RoleManager
import android.widget.Toast
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Optional auto trigger on launch
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager != null && !roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER)
                intent.putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)  // 🔥 Fix here
                startActivityForResult(intent, 1234)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.salate.browser/role")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestDefaultBrowser") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(RoleManager::class.java)
                        if (roleManager != null && !roleManager.isRoleHeld(RoleManager.ROLE_BROWSER)) {
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_BROWSER)
                            intent.putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)  // 🔥 Fix here
                            startActivityForResult(intent, 1234)
                        } else {
                            Toast.makeText(this, "Already default browser", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            }
    }
}
