class ShippingModel {
  final bool succeeded;
  final String? shippingFee;
  final String? message;

  ShippingModel({
    required this.succeeded,
    this.shippingFee,
    this.message
  });

  factory ShippingModel.fromJson(Map<String, dynamic> json) {
    return ShippingModel(
      succeeded: json['succeeded'] ?? false,
      // [FIX]: Thêm .toString() để tránh lỗi ép kiểu từ số (int) sang chuỗi (String)
      shippingFee: json['shipping_fee']?.toString(), 
      message: json['message']?.toString(),
    );
  }
}