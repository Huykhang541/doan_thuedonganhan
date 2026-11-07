class ShippingModel{
  final bool succeeded;
  final String? shippingFee;
  final String? message;

  ShippingModel({
    required this.succeeded,
    this.shippingFee,
    this.message
  });

  factory ShippingModel.fromJson(Map<String,dynamic> json){
    return ShippingModel(
      succeeded: json['succeeded'],
      shippingFee: json['shipping_fee'],
      message: json['message']
    );
  }
}