import '../../features/cart/models/cart_item_model.dart';

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
