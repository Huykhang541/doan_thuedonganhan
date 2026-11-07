class CartResponse {
  final bool succeeded;
  final List<CartItem> data;
  final double totalMoney;

  CartResponse({
    required this.succeeded,
    required this.data,
    required this.totalMoney,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      succeeded: json['succeeded'] ?? false,
      data: (json['data'] as List? ?? []).map((e) => CartItem.fromJson(e)).toList(),
      totalMoney: double.tryParse(json['total_money'].toString()) ?? 0.0,
    );
  }
}

class CartItem {
  int? productVariantId;
  String? productName;
  int? productId; // Đã sửa tên biến cho chuẩn Dart
  double? price;
  int? quantity;
  String? imageUrl;

  CartItem({
    this.productVariantId,
    this.productName,
    this.productId,
    this.price,
    this.quantity,
    this.imageUrl,
  });

  CartItem copyWith({
    int? productVariantId,
    String? productName,
    int? productId,
    String? imageUrl,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      productVariantId: productVariantId ?? this.productVariantId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      productId: productId ?? this.productId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productVariantId: json['product_variant_id'] ?? 0,
      productName: json['name'] ?? '', 
      productId: json['product_id'] ?? 0, 
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      imageUrl: json['image'] ?? '',
    );
  }
}