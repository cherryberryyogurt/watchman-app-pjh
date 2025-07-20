class OrderUnitModel {
  final String? id;
  final int price;
  final String unit;
  final int stock;

  OrderUnitModel({
    this.id,
    required this.price,
    required this.unit,
    this.stock = 0,
  });

  factory OrderUnitModel.fromMap(Map<String, dynamic> map) {
    return OrderUnitModel(
      id: map['id'],
      price: (map['price'] ?? 0),
      unit: map['unit'] ?? '',
      stock: map['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {'price': price, 'unit': unit, 'stock': stock};
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }
}
