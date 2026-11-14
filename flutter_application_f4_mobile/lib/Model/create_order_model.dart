class CreateOrderRequest {
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String couponCode;
  final String note;
  final double totalMoney;
  final String paymentMethod;
  final bool is_buy_now;
  final String ngayThue; 
  final String ngayTra;  
  final List<OrderDetailItem> orderDetails;

  CreateOrderRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.couponCode,
    required this.note,
    required this.totalMoney,
    required this.paymentMethod,
    required this.is_buy_now,
    required this.ngayThue,
    required this.ngayTra,
    required this.orderDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phoneNumber, 
      'address': address,
      'city': city,
      'coupon_code': couponCode,
      'note': note,
      'total_money': totalMoney,
      'payment_method': paymentMethod,
      'is_buy_now': is_buy_now,
      'NgayThue': ngayThue, 
      'NgayTra': ngayTra,   
      'order_details': orderDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderDetailItem {
  final int productId; 
  final int? productVariantId;
  final double price;
  final int quantity;
  final double totalMoney;

  OrderDetailItem({
    required this.productId,
    this.productVariantId,
    required this.price,
    required this.quantity,
    required this.totalMoney,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
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
      // FIX: Tránh hoàn toàn lỗi 'Null' is not subtype of bool
      succeeded: json['succeeded'] == true,
      message: json['message']?.toString() ?? '',
      order_id: (json['order_id'] as num?)?.toInt() ?? 0
    );
  }
}