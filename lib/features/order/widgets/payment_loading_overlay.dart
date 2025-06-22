import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/dimensions.dart';

/// 🔄 결제 처리 중 로딩 오버레이
/// 
/// 결제 처리 중 사용자에게 진행 상황을 보여주고 
/// 타임아웃 처리를 포함한 로딩 상태를 관리합니다.
class PaymentLoadingOverlay extends StatefulWidget {
  final String message;
  final String? subtitle;
  final Duration? timeout;
  final VoidCallback? onTimeout;
  final bool showProgressIndicator;
  final Widget? customIcon;
  
  const PaymentLoadingOverlay({
    super.key,
    this.message = '결제를 처리하고 있습니다...',
    this.subtitle,
    this.timeout,
    this.onTimeout,
    this.showProgressIndicator = true,
    this.customIcon,
  });

  @override
  State<PaymentLoadingOverlay> createState() => _PaymentLoadingOverlayState();
}

class _PaymentLoadingOverlayState extends State<PaymentLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _timeoutTimer;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // 타임아웃 설정
    if (widget.timeout != null) {
      _timeoutTimer = Timer(widget.timeout!, () {
        if (mounted) {
          widget.onTimeout?.call();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(Dimensions.spacingXl),
            padding: const EdgeInsets.all(Dimensions.paddingLg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로딩 인디케이터 또는 커스텀 아이콘
                if (widget.customIcon != null)
                  widget.customIcon!
                else if (widget.showProgressIndicator) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.primary),
                    strokeWidth: 3,
                  ),
                ],
                
                if (widget.showProgressIndicator || widget.customIcon != null)
                  const SizedBox(height: Dimensions.spacingLg),
                
                // 메인 메시지
                Text(
                  widget.message,
                  style: TextStyles.titleMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // 서브타이틀 (선택사항)
                if (widget.subtitle != null) ...[
                  const SizedBox(height: Dimensions.spacingSm),
                  Text(
                    widget.subtitle!,
                    style: TextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                // 타임아웃 경고 (타임아웃 설정 시)
                if (widget.timeout != null) ...[
                  const SizedBox(height: Dimensions.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingMd,
                      vertical: Dimensions.paddingSm,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                      border: Border.all(
                        color: ColorPalette.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: ColorPalette.warning,
                        ),
                        const SizedBox(width: Dimensions.spacingXs),
                        Text(
                          '잠시만 기다려주세요',
                          style: TextStyles.bodySmall.copyWith(
                            color: ColorPalette.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 결제별 특화된 로딩 오버레이들
class PaymentLoadingOverlays {
  /// 결제 승인 처리 중
  static PaymentLoadingOverlay approving({
    VoidCallback? onTimeout,
  }) {
    return PaymentLoadingOverlay(
      message: '결제 승인을 처리하고 있습니다',
      subtitle: '잠시만 기다려주세요',
      timeout: const Duration(seconds: 30),
      onTimeout: onTimeout,
      customIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: ColorPalette.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.credit_card,
          color: ColorPalette.primary,
          size: 30,
        ),
      ),
    );
  }
  
  /// 결제 정보 검증 중
  static PaymentLoadingOverlay validating({
    VoidCallback? onTimeout,
  }) {
    return PaymentLoadingOverlay(
      message: '결제 정보를 검증하고 있습니다',
      timeout: const Duration(seconds: 15),
      onTimeout: onTimeout,
      customIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: ColorPalette.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.verified_user,
          color: ColorPalette.success,
          size: 30,
        ),
      ),
    );
  }
  
  /// 외부 앱 연동 중
  static PaymentLoadingOverlay launching({
    String appName = '결제 앱',
    VoidCallback? onTimeout,
  }) {
    return PaymentLoadingOverlay(
      message: '$appName을 실행하고 있습니다',
      subtitle: '앱에서 결제를 완료해주세요',
      timeout: const Duration(seconds: 60),
      onTimeout: onTimeout,
      customIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: ColorPalette.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.launch,
          color: ColorPalette.primary,
          size: 30,
        ),
      ),
    );
  }
  
  /// 서버 통신 중
  static PaymentLoadingOverlay communicating({
    VoidCallback? onTimeout,
  }) {
    return const PaymentLoadingOverlay(
      message: '서버와 통신하고 있습니다',
      timeout: Duration(seconds: 20),
    );
  }
}