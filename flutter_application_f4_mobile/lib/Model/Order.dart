class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final int price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0, 
      productName: json['product_name'] ?? "Sản phẩm",
      quantity: json['quantity'] ?? 1,
      price: json['price'] ?? 0,
    );
  }
}

class Order {
  final int id;
  final int userId;
  final int totalPrice;
  final String status;
  final String createdAt;
  final String? fullName; 
  final String? phoneNumber;
  final String? address;
  final int shippingFee;
  final double discount;
  final int? couponId;
  List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.discount,
    this.couponId,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.shippingFee = 0,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int parseMoney(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return double.parse(value).toInt();
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    String fullAddress = "";
    if (json['shipping_address'] != null) fullAddress += json['shipping_address'];
    if (json['city'] != null) fullAddress += ", ${json['city']}";
    if (fullAddress.isEmpty && json['address'] != null) fullAddress = json['address'];

    var list = json['items'] as List?;
    List<OrderItem>? itemsList = list?.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      totalPrice: parseMoney(json['total_money'] ?? json['total_price']),
      shippingFee: parseMoney(json['shipping_fee']),
      status: json['status'] ?? "pending",
      createdAt: json['created_at'] ?? "",
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      couponId: json['coupon_id'],
      discount: double.tryParse(json['discount']) ?? 0.0,
      address: fullAddress,
      items: itemsList,
    );
  }
}