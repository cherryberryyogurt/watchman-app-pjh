/// 상품 관련 예외 클래스들
class ProductLocationMismatchException implements Exception {
  final String message;

  ProductLocationMismatchException(this.message);

  @override
  String toString() => '상품 위치가 일치하지 않습니다: $message';
}

class ProductNotFoundException implements Exception {
  final String message;

  ProductNotFoundException(this.message);

  @override
  String toString() => '상품을 찾을 수 없습니다: $message';
}

class ProductOutOfStockException implements Exception {
  final String message;

  ProductOutOfStockException(this.message);

  @override
  String toString() => '상품이 품절되었습니다: $message';
}

class ProductSaleEndedException implements Exception {
  final String message;

  ProductSaleEndedException(this.message);

  @override
  String toString() => '판매가 종료된 상품입니다: $message';
}
