import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// 네트워크 연결 상태 관리 서비스
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// 네트워크 연결 상태 스트림
  static Stream<bool> get connectionStream => _connectionController.stream;

  /// 서비스 초기화
  static Future<void> initialize() async {
    // 초기 연결 상태 확인
    final initialResult = await _connectivity.checkConnectivity();
    final isConnected = _isConnected(initialResult);
    _connectionController.add(isConnected);

    // 연결 상태 변화 모니터링
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = _isConnected(results);
        _connectionController.add(isConnected);
        debugPrint('🌐 네트워크 연결 상태 변경: ${isConnected ? "연결됨" : "연결 끊김"}');
      },
    );
  }

  /// 현재 연결 상태 확인
  static Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnected(result);
    } catch (e) {
      debugPrint('⚠️ 연결 상태 확인 실패: $e');
      return false;
    }
  }

  /// 연결 상태 동기 확인 (캐시된 값)
  static bool get isConnectedSync {
    return _connectionController.hasListener &&
        _connectionController.stream.isBroadcast;
  }

  /// 연결 복구 대기
  static Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = connectionStream.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // 타임아웃 설정
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('네트워크 연결 대기 시간 초과', timeout));
      }
    });

    return completer.future;
  }

  /// 서비스 정리
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }

  /// 연결 상태 판단 (내부 메서드)
  static bool _isConnected(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  /// 연결 타입 가져오기
  static Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return '모바일 데이터';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return '이더넷';
      } else {
        return '연결 없음';
      }
    } catch (e) {
      return '알 수 없음';
    }
  }
}

/// 타임아웃 예외 클래스
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}초)';
}
