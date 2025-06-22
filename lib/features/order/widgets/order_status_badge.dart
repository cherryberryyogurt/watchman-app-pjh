import 'package:flutter/material.dart';

import '../../../core/theme/index.dart';
import '../models/order_enums.dart';

/// 주문 상태 배지 위젯
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? Dimensions.paddingSm : Dimensions.paddingMd,
        vertical: isCompact ? Dimensions.paddingXs : Dimensions.paddingSm,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(
          isCompact ? Dimensions.radiusSm : Dimensions.radiusMd,
        ),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 12 : 14,
            color: config.textColor,
          ),
          const SizedBox(width: Dimensions.spacingXs),
          Text(
            status.displayName,
            style: (isCompact ? TextStyles.bodySmall : TextStyles.bodyMedium)
                .copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 상태별 스타일 설정
  _StatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusConfig(
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          textColor: Colors.orange[700]!,
          icon: Icons.schedule,
        );

      case OrderStatus.confirmed:
        return _StatusConfig(
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[200]!,
          textColor: Colors.blue[700]!,
          icon: Icons.check_circle_outline,
        );

      case OrderStatus.preparing:
        return _StatusConfig(
          backgroundColor: Colors.purple[50]!,
          borderColor: Colors.purple[200]!,
          textColor: Colors.purple[700]!,
          icon: Icons.inventory,
        );

      case OrderStatus.shipped:
        return _StatusConfig(
          backgroundColor: Colors.indigo[50]!,
          borderColor: Colors.indigo[200]!,
          textColor: Colors.indigo[700]!,
          icon: Icons.local_shipping,
        );

      case OrderStatus.readyForPickup:
        return _StatusConfig(
          backgroundColor: Colors.teal[50]!,
          borderColor: Colors.teal[200]!,
          textColor: Colors.teal[700]!,
          icon: Icons.store,
        );

      case OrderStatus.pickedUp:
        return _StatusConfig(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          textColor: Colors.green[700]!,
          icon: Icons.shopping_bag,
        );

      case OrderStatus.delivered:
        return _StatusConfig(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          textColor: Colors.green[700]!,
          icon: Icons.check_circle,
        );

      case OrderStatus.cancelled:
        return _StatusConfig(
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          textColor: Colors.red[700]!,
          icon: Icons.cancel,
        );

      case OrderStatus.finished:
        return _StatusConfig(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          textColor: Colors.green[700]!,
          icon: Icons.done_all,
        );
    }
  }
}

/// 상태별 스타일 설정 클래스
class _StatusConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  const _StatusConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
}
