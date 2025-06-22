import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

/// 네트워크 요청 재시도 서비스
class RetryService {
  /// 지수 백오프를 사용한 재시도 메커니즘
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
    bool waitForConnection = true,
    Duration connectionTimeout = const Duration(seconds: 10),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt < maxRetries) {
      attempt++;

      try {
        // 네트워크 연결 확인 (첫 번째 시도가 아닌 경우)
        if (attempt > 1 && waitForConnection) {
          debugPrint('🔄 재시도 $attempt/$maxRetries - 네트워크 연결 확인 중...');

          if (!await ConnectivityService.isConnected) {
            debugPrint('📶 네트워크 연결 없음 - 연결 복구 대기 중...');

            try {
              await ConnectivityService.waitForConnection(
                  timeout: connectionTimeout);
              debugPrint('✅ 네트워크 연결 복구됨');
            } catch (e) {
              debugPrint('⚠️ 네트워크 연결 복구 실패: $e');
              if (attempt == maxRetries) {
                throw NetworkException('네트워크 연결을 복구할 수 없습니다');
              }
              // 다음 재시도를 위해 대기
              await Future.delayed(currentDelay);
              currentDelay = Duration(
                milliseconds:
                    (currentDelay.inMilliseconds * backoffMultiplier).round(),
              );
              if (currentDelay > maxDelay) currentDelay = maxDelay;
              continue;
            }
          }
        }

        debugPrint('🚀 작업 실행 중... (시도 $attempt/$maxRetries)');
        final result = await operation();

        if (attempt > 1) {
          debugPrint('✅ 재시도 성공! ($attempt번째 시도에서 성공)');
        }

        return result;
      } catch (error) {
        debugPrint('❌ 작업 실패 (시도 $attempt/$maxRetries): $error');

        // 마지막 시도인 경우 예외 재발생
        if (attempt >= maxRetries) {
          debugPrint('💥 최대 재시도 횟수 초과 - 작업 실패');
          rethrow;
        }

        // 재시도 가능한 오류인지 확인
        if (!_isRetryableError(error)) {
          debugPrint('🚫 재시도 불가능한 오류 - 즉시 실패');
          rethrow;
        }

        debugPrint('⏳ ${currentDelay.inSeconds}초 후 재시도...');
        await Future.delayed(currentDelay);

        // 다음 재시도를 위한 지연 시간 증가 (지수 백오프)
        currentDelay = Duration(
          milliseconds:
              (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
        if (currentDelay > maxDelay) currentDelay = maxDelay;
      }
    }

    throw Exception('예상치 못한 재시도 루프 종료');
  }

  /// 조건부 재시도 (사용자 정의 조건)
  static Future<T> withConditionalRetry<T>(
    Future<T> Function() operation, {
    required bool Function(dynamic error) shouldRetry,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt < maxRetries) {
      attempt++;

      try {
        debugPrint('🚀 조건부 재시도 작업 실행 중... (시도 $attempt/$maxRetries)');
        return await operation();
      } catch (error) {
        debugPrint('❌ 조건부 재시도 작업 실패 (시도 $attempt/$maxRetries): $error');

        // 마지막 시도이거나 재시도 조건에 맞지 않는 경우
        if (attempt >= maxRetries || !shouldRetry(error)) {
          if (attempt >= maxRetries) {
            debugPrint('💥 최대 재시도 횟수 초과');
          } else {
            debugPrint('🚫 재시도 조건에 맞지 않음');
          }
          rethrow;
        }

        debugPrint('⏳ ${currentDelay.inSeconds}초 후 조건부 재시도...');
        await Future.delayed(currentDelay);

        currentDelay = Duration(
          milliseconds:
              (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
        if (currentDelay > maxDelay) currentDelay = maxDelay;
      }
    }

    throw Exception('예상치 못한 조건부 재시도 루프 종료');
  }

  /// 타임아웃과 함께 재시도
  static Future<T> withTimeoutAndRetry<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    return withRetry(
      () => operation().timeout(timeout),
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: backoffMultiplier,
    );
  }

  /// 재시도 가능한 오류인지 판단
  static bool _isRetryableError(dynamic error) {
    // 네트워크 관련 오류
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;

    // 문자열 메시지 기반 판단
    final errorString = error.toString().toLowerCase();

    // 네트워크 연결 오류
    if (errorString.contains('network')) return true;
    if (errorString.contains('connection')) return true;
    if (errorString.contains('timeout')) return true;
    if (errorString.contains('unreachable')) return true;
    if (errorString.contains('failed host lookup')) return true;

    // HTTP 상태 코드 기반 판단
    if (errorString.contains('500')) return true; // Internal Server Error
    if (errorString.contains('502')) return true; // Bad Gateway
    if (errorString.contains('503')) return true; // Service Unavailable
    if (errorString.contains('504')) return true; // Gateway Timeout
    if (errorString.contains('429')) return true; // Too Many Requests

    // Firebase 관련 오류
    if (errorString.contains('unavailable')) return true;
    if (errorString.contains('deadline-exceeded')) return true;

    // 기본적으로 재시도하지 않음
    return false;
  }

  /// 네트워크 오류 여부 확인
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup');
  }

  /// 서버 오류 여부 확인 (5xx)
  static bool isServerError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }

  /// 클라이언트 오류 여부 확인 (4xx)
  static bool isClientError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404');
  }
}

/// 네트워크 예외 클래스
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  const NetworkException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'NetworkException: $message (원인: $originalError)';
    }
    return 'NetworkException: $message';
  }
}

/// 재시도 설정 클래스
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool waitForConnection;
  final Duration connectionTimeout;
  final Duration operationTimeout;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.waitForConnection = true,
    this.connectionTimeout = const Duration(seconds: 10),
    this.operationTimeout = const Duration(seconds: 30),
  });

  /// 기본 설정
  static const RetryConfig defaultConfig = RetryConfig();

  /// 빠른 재시도 설정 (짧은 간격)
  static const RetryConfig fastConfig = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 10),
  );

  /// 느린 재시도 설정 (긴 간격)
  static const RetryConfig slowConfig = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 5),
    backoffMultiplier: 3.0,
    maxDelay: Duration(minutes: 2),
  );

  /// 중요한 작업용 설정 (많은 재시도)
  static const RetryConfig criticalConfig = RetryConfig(
    maxRetries: 7,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(minutes: 1),
    connectionTimeout: Duration(seconds: 30),
  );
}
