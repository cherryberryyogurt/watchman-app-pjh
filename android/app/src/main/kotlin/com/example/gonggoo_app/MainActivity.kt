package com.pjh.watchman

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.security.ProviderInstaller

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pjh.watchman/provider_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "installSecurityProvider") {
                try {
                    ProviderInstaller.installIfNeeded(applicationContext)
                    result.success("Security Provider installed successfully")
                } catch (e: GooglePlayServicesRepairableException) {
                    result.error("REPAIRABLE_ERROR", "Google Play Services is repairable: ${e.message}", null)
                } catch (e: GooglePlayServicesNotAvailableException) {
                    result.error("NOT_AVAILABLE_ERROR", "Google Play Services is not available: ${e.message}", null)
                } catch (e: Exception) {
                    result.error("UNKNOWN_ERROR", "Unknown error: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
