class CreateOrderRequest {
  // Các biến final như bạn yêu cầu
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;          // <--- Thêm City
  final String couponCode;    // <--- Thêm Coupon Code
  final String note;
  final double totalMoney;
  final String paymentMethod;
  final bool is_buy_now;
  final List<OrderDetailItem> orderDetails;

  CreateOrderRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,       // <---
    required this.couponCode, // <---
    required this.note,
    required this.totalMoney,
    required this.paymentMethod,
    required this.is_buy_now,
    required this.orderDetails,
  });

  // Map sang JSON để gửi server (dùng snake_case cho chuẩn API)
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phoneNumber,
      'address': address,
      'city': city,                 // Gửi lên server
      'coupon_code': couponCode,    // Gửi lên server
      'note': note,
      'total_money': totalMoney,
      'payment_method': paymentMethod,
      'is_buy_now': is_buy_now,
      'order_details': orderDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderDetailItem {
  final int productVariantId;
  final double price;
  final int quantity;
  final double totalMoney;

  OrderDetailItem({
    required this.productVariantId,
    required this.price,
    required this.quantity,
    required this.totalMoney,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_variant_id': productVariantId,
      'price': price,
      'quantity': quantity,
      'total_money': totalMoney,
    };
  }
}

class CreateOrderResponse {
  final bool succeeded;
  final String message;
  final int order_id;

  CreateOrderResponse({required this.succeeded, required this.message, required this.order_id});

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      succeeded: json['succeeded'] ?? false,
      message: json['message'] ?? '',
      order_id: json['order_id'] ?? 0
    );
  }
}