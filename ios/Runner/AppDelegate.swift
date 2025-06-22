import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 토스 페이먼츠 WebView 설정
    setupWebViewConfiguration()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - 토스 페이먼츠 WebView 설정
  private func setupWebViewConfiguration() {
    // WebView에서 사용할 커스텀 설정이 필요한 경우 여기에 추가
    print("🔧 iOS WebView 설정 완료")
  }
  
  // MARK: - URL 스킴 처리
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 URL 스킴 수신: \(url.absoluteString)")
    
    // 토스 페이먼츠 결제 완료 URL 처리
    if url.scheme == "gonggoo" && url.host == "payment" {
      handlePaymentResult(url: url)
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  // MARK: - 결제 결과 처리
  private func handlePaymentResult(url: URL) {
    print("💳 결제 결과 처리: \(url.absoluteString)")
    
    // Flutter 채널을 통해 결제 결과를 전달
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.pjh.watchman/payment_result",
      binaryMessenger: controller.binaryMessenger
    )
    
    // URL 쿼리 파라미터 파싱
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    var resultData: [String: Any] = [:]
    
    if let queryItems = components?.queryItems {
      for item in queryItems {
        resultData[item.name] = item.value
      }
    }
    
    // Flutter로 결제 결과 전달
    channel.invokeMethod("onPaymentResult", arguments: resultData)
  }
}

// MARK: - 토스 페이먼츠 WebView Navigation Delegate
@objc class TossPaymentsWebViewDelegate: NSObject, WKNavigationDelegate {
  
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    guard let url = navigationAction.request.url else {
      decisionHandler(.allow)
      return
    }
    
    print("🔄 WebView 네비게이션: \(url.absoluteString)")
    
    // HTTP/HTTPS가 아닌 스킴은 외부 앱으로 처리
    if url.scheme != "http" && url.scheme != "https" {
      print("🚀 외부 앱 실행: \(url.absoluteString)")
      
      UIApplication.shared.open(url, options: [:]) { success in
        if !success {
          print("❌ 외부 앱 실행 실패: \(url.absoluteString)")
          // 앱이 설치되어 있지 않을 때의 처리
          self.handleAppNotInstalled(for: url)
        } else {
          print("✅ 외부 앱 실행 성공: \(url.absoluteString)")
        }
      }
      
      decisionHandler(.cancel)
    } else {
      // HTTP/HTTPS는 WebView에서 처리
      decisionHandler(.allow)
    }
  }
  
  // MARK: - 앱 미설치 처리
  private func handleAppNotInstalled(for url: URL) {
    print("📱 앱 미설치 상태 처리: \(url.scheme ?? "unknown")")
    
    // 앱 스킴에 따른 App Store 링크 매핑
    let appStoreLinks: [String: String] = [
      "supertoss": "https://apps.apple.com/app/id839333328", // 토스
      "kakaotalk": "https://apps.apple.com/app/id362057947", // 카카오톡
      "kbbank": "https://apps.apple.com/app/id373742138", // KB스타뱅킹
      "shinhan-sr-ansimclick": "https://apps.apple.com/app/id357484580", // 신한카드
      "hdcardappcardansimclick": "https://apps.apple.com/app/id702653088", // 현대카드
      "lottesmartpay": "https://apps.apple.com/app/id668497947", // 롯데카드
      "citispay": "https://apps.apple.com/app/id1179759666", // 씨티카드
      "samsungpay": "https://apps.apple.com/app/id1141516050", // 삼성페이
      "payco": "https://apps.apple.com/app/id924292102", // PAYCO
      "wooripay": "https://apps.apple.com/app/id1201113419", // 우리페이
    ]
    
    if let scheme = url.scheme,
       let appStoreUrl = appStoreLinks[scheme],
       let storeUrl = URL(string: appStoreUrl) {
      
      UIApplication.shared.open(storeUrl, options: [:]) { success in
        if success {
          print("🏪 App Store로 이동: \(appStoreUrl)")
        } else {
          print("❌ App Store 이동 실패: \(appStoreUrl)")
        }
      }
    }
  }
  
  // MARK: - WebView 로딩 상태 처리
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    print("🔄 WebView 로딩 시작")
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("✅ WebView 로딩 완료")
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    print("❌ WebView 로딩 실패: \(error.localizedDescription)")
  }
}
