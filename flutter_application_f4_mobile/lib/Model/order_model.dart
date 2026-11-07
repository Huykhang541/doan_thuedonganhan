class OrderItem {
  final String id;
  final String name;
  final String? variant;
  final int price;
  int quantity;
  final String image;

  int get totalPrice => price * quantity;

  OrderItem({
    required this.id,
    required this.name,
    this.variant,
    required this.price,
    required this.quantity,
    required this.image,
  });

  // Chuyển từ JSON sang Object (Khi lấy chi tiết đơn hàng cũ)
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'].toString(),
      name: json['name'] as String,
      variant: json['variant'] as String?,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
      image: json['image'] as String,
    );
  }

  // Chuyển từ Object sang JSON (Để gửi lên API tạo đơn hàng)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'variant': variant,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }
}

class OrderModel {
  String receiverName;
  String phoneNumber;
  String address;
  String? note;
  final List<OrderItem> items;
  bool isTransferData;
  bool isExportInvoice;
  bool isOtherRequest;
  String? promoCode;
  int totalAmount;

  OrderModel({
    required this.receiverName,
    required this.phoneNumber,
    required this.address,
    required this.items,
    this.note,
    this.isTransferData = false,
    this.isExportInvoice = false,
    this.isOtherRequest = false,
    this.promoCode,
    required this.totalAmount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      receiverName: json['receiver_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      note: json['note'],
      items: (json['items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      isTransferData: json['is_transfer_data'] ?? false,
      isExportInvoice: json['is_export_invoice'] ?? false,
      isOtherRequest: json['is_other_request'] ?? false,
      promoCode: json['promo_code'],
      totalAmount: json['total_amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiver_name': receiverName,
      'phone_number': phoneNumber,
      'address': address,
      'note': note,
      'items': items.map((i) => i.toJson()).toList(),
      'is_transfer_data': isTransferData,
      'is_export_invoice': isExportInvoice,
      'is_other_request': isOtherRequest,
      'promo_code': promoCode,
      'total_amount': totalAmount,
    };
  }
}