import '../../features/cart/models/cart_item_model.dart';
import '../../features/order/models/refunded_item_model.dart';

/// 세금 계산 유틸리티
///
/// VAT 계산 방식: VAT 포함 가격에서 공급가액과 VAT를 분리
/// 예시: 10,000원 = 공급가액 9,091원 + VAT 909원
class TaxCalculator {
  static const double VAT_RATE = 0.10; // 10%

  /// VAT 포함 가격에서 공급가액과 VAT 분리
  static TaxBreakdown calculateFromVatIncludedPrice(int vatIncludedPrice) {
    final suppliedAmount = (vatIncludedPrice / 1.10).round().toInt();
    final vat = vatIncludedPrice - suppliedAmount;

    return TaxBreakdown(
      suppliedAmount: suppliedAmount,
      vat: vat,
      taxFreeAmount: 0,
      totalAmount: vatIncludedPrice,
    );
  }

  /// 주문 아이템들의 세금 계산
  static OrderTaxBreakdown calculateOrderTax({
    required List<CartItemModel> items,
    required int deliveryFee,
  }) {
    int totalTaxableAmount = 0; // 과세 상품 총액 (VAT 포함)
    int totalTaxFreeAmount = 0; // 면세 상품 총액

    for (final item in items) {
      final int itemTotal = item.priceSum.round();

      if (item.isTaxFree) {
        totalTaxFreeAmount += itemTotal;
      } else {
        totalTaxableAmount += itemTotal;
      }
    }

    // 배송비는 항상 과세 (VAT 포함)
    totalTaxableAmount += deliveryFee;

    // 과세 상품에서 공급가액과 VAT 분리
    final taxableBreakdown = calculateFromVatIncludedPrice(totalTaxableAmount);

    return OrderTaxBreakdown(
      suppliedAmount: taxableBreakdown.suppliedAmount,
      vat: taxableBreakdown.vat,
      taxFreeAmount: totalTaxFreeAmount,
      totalAmount: totalTaxableAmount + totalTaxFreeAmount,
    );
  }

  /// 🔄 전체 주문 환불 시 세금 계산
  ///
  /// 주문의 원본 세금 정보를 기반으로 전액 환불 시 세금 분해를 계산합니다.
  static RefundTaxBreakdown calculateFullRefundTax({
    required int totalRefundAmount,
    required int originalSuppliedAmount,
    required int originalVat,
    required int originalTaxFreeAmount,
  }) {
    // 전액 환불인 경우 원본 세금 정보를 그대로 사용
    return RefundTaxBreakdown(
      cancelAmount: totalRefundAmount,
      cancelTaxableAmount: originalSuppliedAmount,
      cancelVat: originalVat,
      cancelTaxFreeAmount: originalTaxFreeAmount,
    );
  }

  /// 🔄 부분 환불 시 세금 계산 (비율 기반)
  ///
  /// 원본 주문 대비 환불 비율을 계산하여 세금을 분배합니다.
  static RefundTaxBreakdown calculatePartialRefundTax({
    required int totalRefundAmount,
    required int originalTotalAmount,
    required int originalSuppliedAmount,
    required int originalVat,
    required int originalTaxFreeAmount,
  }) {
    if (originalTotalAmount == 0) {
      throw ArgumentError('원본 주문 금액이 0일 수 없습니다.');
    }

    // 환불 비율 계산
    final refundRatio = totalRefundAmount / originalTotalAmount;

    // 비율에 따른 세금 분배
    final cancelTaxFreeAmount = (originalTaxFreeAmount * refundRatio).round();
    final cancelTaxableAmount = (originalSuppliedAmount * refundRatio).round();
    final cancelVat = (originalVat * refundRatio).round();

    // 반올림 오차 보정
    final calculatedTotal =
        cancelTaxFreeAmount + cancelTaxableAmount + cancelVat;
    final difference = totalRefundAmount - calculatedTotal;

    // 오차가 있으면 과세 공급가액에서 조정 (가장 큰 항목)
    final adjustedCancelTaxableAmount = cancelTaxableAmount + difference;

    return RefundTaxBreakdown(
      cancelAmount: totalRefundAmount,
      cancelTaxableAmount: adjustedCancelTaxableAmount,
      cancelVat: cancelVat,
      cancelTaxFreeAmount: cancelTaxFreeAmount,
    );
  }

  /// 🔄 아이템별 환불 시 세금 계산
  ///
  /// 환불할 개별 상품들의 면세 여부를 확인하여 정확한 세금 분해를 계산합니다.
  static RefundTaxBreakdown calculateItemLevelRefundTax({
    required List<RefundedItemModel> refundedItems,
  }) {
    int totalTaxableAmount = 0; // 과세 상품 총액 (VAT 포함)
    int totalTaxFreeAmount = 0; // 면세 상품 총액

    // 환불 상품별로 과세/면세 분류
    for (final item in refundedItems) {
      if (item.isTaxFree) {
        totalTaxFreeAmount += item.totalRefundAmount;
      } else {
        totalTaxableAmount += item.totalRefundAmount;
      }
    }

    // 과세 상품에서 공급가액과 VAT 분리
    int cancelTaxableAmount = 0;
    int cancelVat = 0;

    if (totalTaxableAmount > 0) {
      final taxableBreakdown =
          calculateFromVatIncludedPrice(totalTaxableAmount);
      cancelTaxableAmount = taxableBreakdown.suppliedAmount;
      cancelVat = taxableBreakdown.vat;
    }

    final totalRefundAmount = totalTaxableAmount + totalTaxFreeAmount;

    return RefundTaxBreakdown(
      cancelAmount: totalRefundAmount,
      cancelTaxableAmount: cancelTaxableAmount,
      cancelVat: cancelVat,
      cancelTaxFreeAmount: totalTaxFreeAmount,
    );
  }

  /// 🔄 환불 세금 계산 (통합 메서드)
  ///
  /// 환불 유형에 따라 적절한 세금 계산 방법을 선택합니다.
  static RefundTaxBreakdown calculateRefundTax({
    required int totalRefundAmount,
    required int originalTotalAmount,
    required int originalSuppliedAmount,
    required int originalVat,
    required int originalTaxFreeAmount,
    List<RefundedItemModel>? refundedItems,
  }) {
    // 아이템별 환불인 경우
    if (refundedItems != null && refundedItems.isNotEmpty) {
      return calculateItemLevelRefundTax(refundedItems: refundedItems);
    }

    // 전액 환불인 경우
    if (totalRefundAmount == originalTotalAmount) {
      return calculateFullRefundTax(
        totalRefundAmount: totalRefundAmount,
        originalSuppliedAmount: originalSuppliedAmount,
        originalVat: originalVat,
        originalTaxFreeAmount: originalTaxFreeAmount,
      );
    }

    // 부분 환불인 경우 (비율 기반)
    return calculatePartialRefundTax(
      totalRefundAmount: totalRefundAmount,
      originalTotalAmount: originalTotalAmount,
      originalSuppliedAmount: originalSuppliedAmount,
      originalVat: originalVat,
      originalTaxFreeAmount: originalTaxFreeAmount,
    );
  }
}

/// 세금 분해 결과
class TaxBreakdown {
  final int suppliedAmount; // 공급가액
  final int vat; // 부가세
  final int taxFreeAmount; // 면세 금액
  final int totalAmount; // 총 금액

  const TaxBreakdown({
    required this.suppliedAmount,
    required this.vat,
    required this.taxFreeAmount,
    required this.totalAmount,
  });
}

/// 주문 세금 분해 결과
class OrderTaxBreakdown extends TaxBreakdown {
  const OrderTaxBreakdown({
    required super.suppliedAmount,
    required super.vat,
    required super.taxFreeAmount,
    required super.totalAmount,
  });

  /// 토스페이먼츠 API용 Map 변환
  Map<String, dynamic> toTossPaymentsMap() {
    return {
      'suppliedAmount': suppliedAmount,
      'vat': vat,
      'taxFreeAmount': taxFreeAmount,
      'totalAmount': totalAmount,
    };
  }

  /// 디버그용 문자열 표현
  @override
  String toString() {
    return 'OrderTaxBreakdown(suppliedAmount: $suppliedAmount, vat: $vat, taxFreeAmount: $taxFreeAmount, totalAmount: $totalAmount)';
  }
}

/// 🔄 환불 세금 분해 결과
///
/// 토스페이먼츠 결제 취소 API에 전달할 세금 정보를 포함합니다.
class RefundTaxBreakdown {
  /// 총 취소 금액
  final int cancelAmount;

  /// 취소할 과세 공급가액 (VAT 제외)
  final int cancelTaxableAmount;

  /// 취소할 VAT 금액
  final int cancelVat;

  /// 취소할 면세 금액
  final int cancelTaxFreeAmount;

  const RefundTaxBreakdown({
    required this.cancelAmount,
    required this.cancelTaxableAmount,
    required this.cancelVat,
    required this.cancelTaxFreeAmount,
  });

  /// 토스페이먼츠 v1 API 취소용 Map 변환 (v1 API는 taxFreeAmount만 지원)
  Map<String, dynamic> toTossPaymentsCancelMap() {
    return {
      'cancelAmount': cancelAmount,
      'taxFreeAmount': cancelTaxFreeAmount, // v1 API는 taxFreeAmount만 지원
    };
  }

  /// 토스페이먼츠 v2 API 취소용 Map 변환 (하위 호환성)
  Map<String, dynamic> toTossPaymentsV2CancelMap() {
    return {
      'cancelAmount': cancelAmount,
      'cancelTaxableAmount': cancelTaxableAmount,
      'cancelVat': cancelVat,
      'cancelTaxFreeAmount': cancelTaxFreeAmount,
    };
  }

  /// TossPayments v1 API에서 사용할 taxFreeAmount 값
  int get taxFreeAmount => cancelTaxFreeAmount;

  /// 검증: 총액이 일치하는지 확인
  bool get isValid {
    return cancelAmount ==
        (cancelTaxableAmount + cancelVat + cancelTaxFreeAmount);
  }

  /// 디버그용 문자열 표현
  @override
  String toString() {
    return 'RefundTaxBreakdown(cancelAmount: $cancelAmount, cancelTaxableAmount: $cancelTaxableAmount, cancelVat: $cancelVat, cancelTaxFreeAmount: $cancelTaxFreeAmount, isValid: $isValid)';
  }
}
