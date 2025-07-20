import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/index.dart';
import '../../../core/widgets/loading_modal.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../providers/order_history_state.dart';
import '../services/order_service.dart';
import 'order_status_badge.dart';
import 'pickup_verification_modal.dart';

/// 주문 내역 아이템 위젯
///
/// 홈 화면과 주문 내역 화면에서 공통으로 사용되는 주문 아이템 컴포넌트입니다.
class OrderHistoryItem extends ConsumerWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final bool isCompact;

  const OrderHistoryItem({
    super.key,
    required this.order,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final priceFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    // 주문 정보 표시 (비정규화된 데이터 사용)
    final productName = order.representativeProductName ?? '상품명 없음';
    final additionalItemsCount =
        order.totalProductCount > 1 ? order.totalProductCount - 1 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radius),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 주문 헤더 (배송 완료 상태 및 날짜)
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSm),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[800]?.withOpacity(0.3)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radius),
                topRight: Radius.circular(Dimensions.radius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatOrderDate(order.createdAt),
                  style: TextStyles.bodySmall.copyWith(
                    color: isDarkMode
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                  ),
                ),
                OrderStatusBadge(status: order.status, isCompact: isCompact),
              ],
            ),
          ),

          // 상품 정보 섹션
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(Dimensions.radius),
              bottomRight: Radius.circular(Dimensions.radius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSm),
              child: Column(
                children: [
                  // 상품 이미지 및 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품 이미지 (플레이스홀더)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: isDarkMode
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight,
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: Dimensions.spacingSm),

                      // 상품 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상품명
                            Text(
                              productName,
                              style: TextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (additionalItemsCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '외 ${additionalItemsCount}개',
                                style: TextStyles.bodySmall.copyWith(
                                  color: isDarkMode
                                      ? ColorPalette.textSecondaryDark
                                      : ColorPalette.textSecondaryLight,
                                ),
                              ),
                            ],

                            const SizedBox(height: Dimensions.spacingXs),

                            // 가격 정보
                            Text(
                              priceFormat.format(order.totalAmount),
                              style: TextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? ColorPalette.textPrimaryDark
                                    : ColorPalette.textPrimaryLight,
                              ),
                            ),

                            // 운송장 번호 표시 (택배/배송 상품에만)
                            if (order.deliveryType ==
                                DeliveryType.delivery) ...[
                              const SizedBox(height: Dimensions.spacingXs),
                              if (order.deliveryCompanyName != null) ...[
                                Text(
                                  '택배사: ${order.deliveryCompanyName}',
                                  style: TextStyles.bodySmall.copyWith(
                                    color: isDarkMode
                                        ? ColorPalette.textSecondaryDark
                                        : ColorPalette.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              _buildTrackingNumberWidget(
                                  context, order, isDarkMode),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spacingMd),

                  // 액션 버튼들
                  _buildActionButtons(context, ref, order, isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 주문일자 포맷팅
  String _formatOrderDate(DateTime date) {
    return DateFormat('M/d 주문').format(date);
  }

  /// 운송장 번호 위젯 (클립보드 기능 포함)
  Widget _buildTrackingNumberWidget(
      BuildContext context, OrderModel order, bool isDarkMode) {
    final hasTrackingNumber =
        order.trackingNumber != null && order.trackingNumber!.isNotEmpty;

    if (hasTrackingNumber) {
      return GestureDetector(
        onTap: () => _copyTrackingNumber(context, order.trackingNumber!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ColorPalette.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ColorPalette.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '운송장: ${order.trackingNumber}',
                style: TextStyles.bodySmall.copyWith(
                  color: ColorPalette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.copy,
                size: 14,
                color: ColorPalette.primary,
              ),
            ],
          ),
        ),
      );
    } else {
      return Text(
        '운송장: 등록되지 않았습니다',
        style: TextStyles.bodySmall.copyWith(
          color: isDarkMode
              ? ColorPalette.textSecondaryDark
              : ColorPalette.textSecondaryLight,
        ),
      );
    }
  }

  /// 운송장 번호 클립보드 복사
  void _copyTrackingNumber(BuildContext context, String trackingNumber) async {
    await Clipboard.setData(ClipboardData(text: trackingNumber));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('운송장 번호가 클립보드에 복사되었습니다: $trackingNumber'),
          duration: const Duration(seconds: 2),
          backgroundColor: ColorPalette.success,
        ),
      );
    }
  }

  /// 액션 버튼들 빌드 (상태에 따라 다른 버튼 표시)
  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, OrderModel order, bool isDarkMode) {
    switch (order.status) {
      case OrderStatus.pending:
        // pending 주문: Delete 버튼만 표시
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showDeleteOrderDialog(context, ref, order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.error,
                  side: const BorderSide(color: ColorPalette.error),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Text(
                  '삭제',
                  style: TextStyles.bodySmall,
                ),
              ),
            ),
          ],
        );

      case OrderStatus.readyForPickup:
        // pickup_ready 주문: Verify Pickup + View Details 버튼
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    _showPickupVerificationDialog(context, ref, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Text(
                  '픽업 인증',
                  style: TextStyles.bodySmall,
                ),
              ),
            ),
            const SizedBox(width: Dimensions.spacingSm),
            Expanded(
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkMode
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Text(
                  '상세 보기',
                  style: TextStyles.bodySmall,
                ),
              ),
            ),
          ],
        );

      case OrderStatus.pickedUp:
        // picked_up 주문: 픽업 인증 완료 상태 - 회색 버튼으로 인증 이미지 보기 + View Details
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    _showPickupVerificationDialog(context, ref, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.grey[200] : Colors.grey[400],
                  foregroundColor:
                      isDarkMode ? Colors.grey[200] : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isDarkMode ? Colors.grey[200] : Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '픽업 완료',
                      style: TextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Dimensions.spacingSm),
            Expanded(
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkMode
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Text(
                  '상세 보기',
                  style: TextStyles.bodySmall,
                ),
              ),
            ),
          ],
        );

      default:
        // 기존 로직 (다른 상태들)
        return Row(
          children: [
            // 동적 액션 버튼 (주문 취소 / 환불 요청)
            if (_shouldShowActionButton(order.status))
              Expanded(
                child: _buildActionButton(context, ref, order, isDarkMode),
              ),

            if (_shouldShowActionButton(order.status))
              const SizedBox(width: Dimensions.spacingSm),

            // 상세 보기 버튼
            Expanded(
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkMode
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight,
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingXs,
                  ),
                ),
                child: Text(
                  '상세 보기',
                  style: TextStyles.bodySmall,
                ),
              ),
            ),
          ],
        );
    }
  }

  /// 동적 액션 버튼 빌드
  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, OrderModel order, bool isDarkMode) {
    final String buttonText = _getActionButtonText(order.status);
    final VoidCallback? onPressed =
        _getActionButtonCallback(context, ref, order);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDarkMode
            ? ColorPalette.textSecondaryDark
            : ColorPalette.textSecondaryLight,
        side: BorderSide(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingXs,
        ),
      ),
      child: Text(
        buttonText,
        style: TextStyles.bodySmall,
      ),
    );
  }

  /// 액션 버튼 텍스트 결정
  String _getActionButtonText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return '주문 취소';
      default:
        return '';
    }
  }

  /// 액션 버튼 콜백 결정
  VoidCallback? _getActionButtonCallback(
      BuildContext context, WidgetRef ref, OrderModel order) {
    switch (order.status) {
      case OrderStatus.confirmed:
        return () => _showCancelOrderDialog(context, ref, order);
      default:
        return null;
    }
  }

  /// 액션 버튼 표시 여부 확인
  bool _shouldShowActionButton(OrderStatus status) {
    // cancelled, finished, refunded, confirmed 상태에서는 액션 버튼 숨김
    if (status == OrderStatus.cancelled ||
        status == OrderStatus.finished ||
        status == OrderStatus.refunded ||
        status == OrderStatus.confirmed) {
      return false;
    }

    return true;
  }

  /// 주문 취소 다이얼로그
  void _showCancelOrderDialog(
      BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: const Text('정말로 주문을 취소하시겠습니까?\n취소된 주문은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(context, ref, order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }

  /// 주문 취소 실행
  void _cancelOrder(
      BuildContext context, WidgetRef ref, OrderModel order) async {
    // 로딩 모달 표시
    final dismissModal = LoadingModal.show(
      context,
      message: '주문 취소가 처리중입니다.',
    );

    try {
      await ref.read(orderServiceProvider).cancelOrder(
            orderId: order.orderId,
            cancelReason: '고객 요청',
          );

      // 모달 닫기
      dismissModal();

      // 성공 시: 성공 메시지 표시
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('주문이 성공적으로 취소되었습니다.'),
          backgroundColor: ColorPalette.success,
        ),
      );

      // 주문 목록 새로고침
      ref.read(orderHistoryProvider.notifier).refreshOrders();
    } catch (e) {
      // 모달 닫기
      dismissModal();

      // 실패 시: 에러 메시지 표시
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 취소에 실패했습니다: ${e.toString()}'),
          backgroundColor: ColorPalette.error,
        ),
      );
    }
  }

  /// 주문 삭제 다이얼로그 (pending 상태)
  void _showDeleteOrderDialog(
      BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 삭제'),
        content: const Text('정말로 주문을 삭제하시겠습니까?\n삭제된 주문은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(context, ref, order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 픽업 인증 다이얼로그
  void _showPickupVerificationDialog(
      BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => PickupVerificationModal(order: order),
    ).then((result) {
      if (result == true) {
        // 성공 시 주문 목록 새로고침
        ref.read(orderHistoryProvider.notifier).refreshOrders();

        // 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('픽업 인증이 완료되었습니다. 주문 상태가 업데이트되었습니다.'),
              backgroundColor: ColorPalette.success,
            ),
          );
        }
      }
    });
  }

  /// 주문 삭제 실행
  void _deleteOrder(
      BuildContext context, WidgetRef ref, OrderModel order) async {
    // 로딩 모달 표시
    final dismissModal = LoadingModal.show(
      context,
      message: '주문을 삭제하는 중입니다.',
    );

    try {
      // 주문 삭제 및 재고 복구
      await ref.read(orderServiceProvider).deleteOrderAndRestoreStock(
            orderId: order.orderId,
          );

      // 모달 닫기
      dismissModal();

      // 성공 시: 성공 메시지 표시
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주문이 성공적으로 삭제되었습니다.'),
          backgroundColor: ColorPalette.success,
        ),
      );

      // 주문 목록 새로고침
      ref.read(orderHistoryProvider.notifier).refreshOrders();
    } catch (e) {
      // 모달 닫기
      dismissModal();

      // 실패 시: 에러 메시지 표시
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 삭제에 실패했습니다: ${e.toString()}'),
          backgroundColor: ColorPalette.error,
        ),
      );
    }
  }
}
