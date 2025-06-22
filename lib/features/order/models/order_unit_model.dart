class OrderUnitModel {
  final String? id;
  final double price;
  final String quantity;

  OrderUnitModel({this.id, required this.price, required this.quantity});

  factory OrderUnitModel.fromMap(Map<String, dynamic> map) {
    return OrderUnitModel(
      id: map['id'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = {'price': price, 'quantity': quantity};
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }
}
