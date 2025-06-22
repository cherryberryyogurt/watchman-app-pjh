import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 🔄 자동 재시도 헬퍼
///
/// 네트워크 요청이나 결제 처리에서 일시적 오류 발생 시
/// 지수 백오프(Exponential Backoff) 방식으로 자동 재시도를 수행합니다.
class RetryHelper {
  /// 기본 재시도 설정
  static const int defaultMaxRetries = 3;
  static const Duration defaultInitialDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(seconds: 30);

  /// 지수 백오프 방식으로 재시도 수행
  ///
  /// [operation]: 재시도할 비동기 작업
  /// [maxRetries]: 최대 재시도 횟수
  /// [initialDelay]: 초기 지연 시간
  /// [backoffMultiplier]: 지연 시간 증가 배수
  /// [maxDelay]: 최대 지연 시간
  /// [shouldRetry]: 재시도 여부를 결정하는 함수
  /// [onRetry]: 재시도 시 호출되는 콜백
  static Future<T> exponentialBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        final result = await operation();

        // 성공 시 로깅
        if (attempt > 0 && kDebugMode) {
          debugPrint(
              '🎉 RetryHelper: 재시도 성공 (시도: ${attempt + 1}/${maxRetries + 1})');
        }

        return result;
      } catch (error) {
        attempt++;

        // 재시도 여부 확인
        final canRetry = shouldRetry?.call(error) ?? defaultShouldRetry(error);

        if (!canRetry || attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 재시도 포기 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
          }
          rethrow;
        }

        // 재시도 콜백 호출
        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint(
              '⏳ RetryHelper: 재시도 대기 중 (시도: $attempt/${maxRetries + 1}, 지연: ${currentDelay.inSeconds}초, 오류: $error)');
        }

        // 지연 후 재시도
        await Future.delayed(currentDelay);

        // 다음 지연 시간 계산 (지수 백오프 + 지터)
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * backoffMultiplier).round(),
            maxDelay.inMilliseconds,
          ),
        );

        // 지터 추가 (±25% 랜덤)
        final jitter = Random().nextDouble() * 0.5 - 0.25; // -0.25 ~ +0.25
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * (1 + jitter)).round(),
        );
      }
    }
  }

  /// 선형 백오프 방식으로 재시도 수행
  ///
  /// 지수 백오프보다 보수적인 방식으로, 일정한 간격으로 지연 시간을 증가시킵니다.
  static Future<T> linearBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    Duration delayIncrement = const Duration(seconds: 1),
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        final result = await operation();

        if (attempt > 0 && kDebugMode) {
          debugPrint(
              '🎉 RetryHelper: 선형 백오프 재시도 성공 (시도: ${attempt + 1}/${maxRetries + 1})');
        }

        return result;
      } catch (error) {
        attempt++;

        final canRetry = shouldRetry?.call(error) ?? defaultShouldRetry(error);

        if (!canRetry || attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 선형 백오프 재시도 포기 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
          }
          rethrow;
        }

        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint(
              '⏳ RetryHelper: 선형 백오프 재시도 대기 중 (시도: $attempt/${maxRetries + 1}, 지연: ${currentDelay.inSeconds}초)');
        }

        await Future.delayed(currentDelay);

        // 선형 증가
        currentDelay = Duration(
          milliseconds: min(
            currentDelay.inMilliseconds + delayIncrement.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// 고정 간격 재시도
  ///
  /// 매번 동일한 간격으로 재시도합니다.
  static Future<T> fixedInterval<T>({
    required Future<T> Function() operation,
    int maxRetries = defaultMaxRetries,
    Duration interval = defaultInitialDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        final result = await operation();

        if (attempt > 0 && kDebugMode) {
          debugPrint(
              '🎉 RetryHelper: 고정 간격 재시도 성공 (시도: ${attempt + 1}/${maxRetries + 1})');
        }

        return result;
      } catch (error) {
        attempt++;

        final canRetry = shouldRetry?.call(error) ?? defaultShouldRetry(error);

        if (!canRetry || attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 고정 간격 재시도 포기 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
          }
          rethrow;
        }

        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint(
              '⏳ RetryHelper: 고정 간격 재시도 대기 중 (시도: $attempt/${maxRetries + 1}, 간격: ${interval.inSeconds}초)');
        }

        await Future.delayed(interval);
      }
    }
  }

  /// 즉시 재시도 (지연 없음)
  ///
  /// 빠른 재시도가 필요한 경우 사용합니다.
  static Future<T> immediate<T>({
    required Future<T> Function() operation,
    int maxRetries = 2, // 즉시 재시도는 보통 적은 횟수
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        final result = await operation();

        if (attempt > 0 && kDebugMode) {
          debugPrint(
              '🎉 RetryHelper: 즉시 재시도 성공 (시도: ${attempt + 1}/${maxRetries + 1})');
        }

        return result;
      } catch (error) {
        attempt++;

        final canRetry = shouldRetry?.call(error) ?? defaultShouldRetry(error);

        if (!canRetry || attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 즉시 재시도 포기 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
          }
          rethrow;
        }

        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint('🔄 RetryHelper: 즉시 재시도 (시도: $attempt/${maxRetries + 1})');
        }
      }
    }
  }

  /// 조건부 재시도
  ///
  /// 특정 조건을 만족할 때까지 재시도합니다.
  static Future<T> untilCondition<T>({
    required Future<T> Function() operation,
    required bool Function(T result) condition,
    int maxRetries = defaultMaxRetries,
    Duration interval = defaultInitialDelay,
    void Function(int attempt, T result)? onConditionFailed,
  }) async {
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        final result = await operation();

        if (condition(result)) {
          if (attempt > 0 && kDebugMode) {
            debugPrint(
                '🎉 RetryHelper: 조건 만족 (시도: ${attempt + 1}/${maxRetries + 1})');
          }
          return result;
        }

        attempt++;
        onConditionFailed?.call(attempt, result);

        if (attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 조건 미만족으로 재시도 포기 (시도: $attempt/${maxRetries + 1})');
          }
          return result; // 마지막 결과 반환
        }

        if (kDebugMode) {
          debugPrint(
              '⏳ RetryHelper: 조건 미만족, 재시도 대기 중 (시도: $attempt/${maxRetries + 1})');
        }

        await Future.delayed(interval);
      } catch (error) {
        attempt++;

        if (attempt > maxRetries) {
          if (kDebugMode) {
            debugPrint(
                '🔴 RetryHelper: 조건부 재시도 중 오류로 포기 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
          }
          rethrow;
        }

        if (kDebugMode) {
          debugPrint(
              '⏳ RetryHelper: 조건부 재시도 중 오류, 대기 중 (시도: $attempt/${maxRetries + 1}, 오류: $error)');
        }

        await Future.delayed(interval);
      }
    }

    throw StateError('조건부 재시도가 예상치 못하게 종료되었습니다.');
  }

  /// 기본 재시도 조건 확인
  ///
  /// 네트워크 오류, 서버 오류 등 일시적 오류인 경우 재시도를 허용합니다.
  static bool defaultShouldRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 네트워크 관련 오류
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('dns') ||
        errorString.contains('socket')) {
      return true;
    }

    // HTTP 상태 코드 기반 판단
    if (errorString.contains('500') || // Internal Server Error
        errorString.contains('502') || // Bad Gateway
        errorString.contains('503') || // Service Unavailable
        errorString.contains('504') || // Gateway Timeout
        errorString.contains('429')) {
      // Too Many Requests
      return true;
    }

    // Firebase Functions 오류
    if (errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded') ||
        errorString.contains('resource-exhausted')) {
      return true;
    }

    return false;
  }

  /// 재시도 통계 수집
  static void logRetryStats({
    required String operation,
    required int totalAttempts,
    required Duration totalDuration,
    required bool success,
    dynamic finalError,
  }) {
    if (kDebugMode) {
      final status = success ? '성공' : '실패';
      debugPrint('📊 RetryHelper 통계: $operation - $status');
      debugPrint('   총 시도: $totalAttempts회');
      debugPrint('   총 소요시간: ${totalDuration.inMilliseconds}ms');
      if (!success && finalError != null) {
        debugPrint('   최종 오류: $finalError');
      }
    }
  }
}

/// 재시도 설정 클래스
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(dynamic error)? shouldRetry;
  final void Function(int attempt, dynamic error)? onRetry;

  const RetryConfig({
    this.maxRetries = RetryHelper.defaultMaxRetries,
    this.initialDelay = RetryHelper.defaultInitialDelay,
    this.backoffMultiplier = RetryHelper.defaultBackoffMultiplier,
    this.maxDelay = RetryHelper.defaultMaxDelay,
    this.shouldRetry,
    this.onRetry,
  });

  /// RetryConfig 복사 생성자
  RetryConfig copyWith({
    int? maxRetries,
    Duration? initialDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) {
    return RetryConfig(
      maxRetries: maxRetries ?? this.maxRetries,
      initialDelay: initialDelay ?? this.initialDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxDelay: maxDelay ?? this.maxDelay,
      shouldRetry: shouldRetry ?? this.shouldRetry,
      onRetry: onRetry ?? this.onRetry,
    );
  }

  /// 네트워크 요청용 기본 설정
  static const network = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 30),
  );

  /// 결제 처리용 설정 (더 보수적)
  static const payment = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 10),
  );

  /// 빠른 재시도용 설정
  static const quick = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 3),
  );

  /// 느린 재시도용 설정 (서버 부하 고려)
  static const slow = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(seconds: 5),
    backoffMultiplier: 1.2,
    maxDelay: Duration(minutes: 2),
  );
}

/// RetryHelper 확장 메서드
extension RetryExtension<T> on Future<T> Function() {
  /// 기본 지수 백오프로 재시도
  Future<T> retry([RetryConfig config = RetryConfig.network]) {
    return RetryHelper.exponentialBackoff<T>(
      operation: this,
      maxRetries: config.maxRetries,
      initialDelay: config.initialDelay,
      backoffMultiplier: config.backoffMultiplier,
      maxDelay: config.maxDelay,
      shouldRetry: config.shouldRetry,
      onRetry: config.onRetry,
    );
  }

  /// 선형 백오프로 재시도
  Future<T> retryLinear([RetryConfig config = RetryConfig.network]) {
    return RetryHelper.linearBackoff<T>(
      operation: this,
      maxRetries: config.maxRetries,
      initialDelay: config.initialDelay,
      delayIncrement: Duration(seconds: 1),
      maxDelay: config.maxDelay,
      shouldRetry: config.shouldRetry,
      onRetry: config.onRetry,
    );
  }

  /// 고정 간격으로 재시도
  Future<T> retryFixed([RetryConfig config = RetryConfig.network]) {
    return RetryHelper.fixedInterval<T>(
      operation: this,
      maxRetries: config.maxRetries,
      interval: config.initialDelay,
      shouldRetry: config.shouldRetry,
      onRetry: config.onRetry,
    );
  }

  /// 즉시 재시도
  Future<T> retryImmediate([int maxRetries = 2]) {
    return RetryHelper.immediate<T>(
      operation: this,
      maxRetries: maxRetries,
    );
  }
}
