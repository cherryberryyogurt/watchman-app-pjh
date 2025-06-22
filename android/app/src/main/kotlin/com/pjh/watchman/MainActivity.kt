package com.pjh.watchman

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.security.ProviderInstaller
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebResourceRequest
import android.webkit.URLUtil
import android.net.Uri
import android.content.Intent
import android.content.ActivityNotFoundException
import android.os.Build
import java.net.URISyntaxException

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

    // 토스 페이먼츠 웹뷰를 위한 WebViewClient 클래스
    inner class TossPaymentsWebViewClient : WebViewClient() {
        // API 수준 24 이상을 위한 메서드
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            val url = request.url.toString()
            return handleUrl(url)
        }

        // (선택) API 수준 24 미만을 타게팅 하려면 다음 코드를 추가해 주세요
        @Deprecated("Deprecated in Java")
        @Suppress("DEPRECATION")
        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                return handleUrl(url)
            }
            return super.shouldOverrideUrlLoading(view, url)
        }

        // 공통 URL 처리 로직
        private fun handleUrl(url: String): Boolean {
            if (!URLUtil.isNetworkUrl(url) && !URLUtil.isJavaScriptUrl(url)) {
                val uri = try {
                    Uri.parse(url)
                } catch (e: Exception) {
                    return false
                }
                return when (uri.scheme) {
                    "intent" -> {
                        startSchemeIntent(url)
                    }
                    else -> {
                        return try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            true
                        } catch (e: Exception) {
                            false
                        }
                    }
                }
            } else {
                return false
            }
        }

        private fun startSchemeIntent(url: String): Boolean {
            val schemeIntent: Intent = try {
                Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
            } catch (e: URISyntaxException) {
                return false
            }
            try {
                startActivity(schemeIntent)
                return true
            } catch (e: ActivityNotFoundException) {
                val packageName = schemeIntent.getPackage()
                if (!packageName.isNullOrBlank()) {
                    startActivity(
                        Intent(
                            Intent.ACTION_VIEW,
                            Uri.parse("market://details?id=$packageName")
                        )
                    )
                    return true
                }
            }
            return false
        }
    }
}
