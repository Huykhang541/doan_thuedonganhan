class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final int price;
  final int? variantId; 
  final String? imageUrl;
  final String? color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.variantId,
    this.imageUrl,
    this.color,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    // Lấy ID biến thể chuẩn từ cột MaBienThe của Backend
    int? parsedVariantId;
    if (json['MaBienThe'] != null) {
      parsedVariantId = parseInt(json['MaBienThe']);
    } else if (json['variantId'] != null) {
      parsedVariantId = parseInt(json['variantId']);
    } else if (json['product_variant_id'] != null) {
      parsedVariantId = parseInt(json['product_variant_id']);
    }

    return OrderItem(
      productId: parseInt(json['productId'] ?? json['MaSanPham'] ?? json['product_id']),
      productName: json['productName'] ?? json['TenSanPham'] ?? json['product_name'] ?? "Sản phẩm",
      quantity: parseInt(json['quantity'] ?? json['SoLuong'] ?? 1),
      price: parseInt(json['price'] ?? json['ThanhTien'] ?? json['GiaThueTheoNgay'] ?? json['DonGiaThue']),
      variantId: parsedVariantId,
      imageUrl: json['imageUrl'] ?? json['DuongDanAnh'] ?? json['image_url'] ?? json['image'],
      color: json['MauSac'] ?? json['color'],
    );
  }
}

class Order {
  final int id;
  final int userId;
  final int rentalFee;   // [FIX 1]: Thêm thuộc tính Tiền thuê thuần túy
  final int depositFee;  // [FIX 2]: Thêm thuộc tính Tiền cọc
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
    this.rentalFee = 0,
    this.depositFee = 0,
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
    int parseNumber(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return double.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    String addr = json['address'] ?? json['DiaChiGiaoHang'] ?? json['shipping_address'] ?? "";
    String city = json['city'] ?? "";
    String fullAddress = addr;
    if (addr.isNotEmpty && city.isNotEmpty && !addr.contains(city)) {
      fullAddress = "$addr, $city";
    }

    var list = json['items'] as List?;
    List<OrderItem>? itemsList = list?.map((i) {
      if (i is Map) {
        return OrderItem.fromJson(Map<String, dynamic>.from(i));
      }
      return OrderItem.fromJson({});
    }).toList();

    // [FIX 3]: Parse đủ 3 khoản tiền từ Backend để tính tổng chính xác
    int rFee = parseNumber(json['rentalFee'] ?? json['TongTienThue']);
    int dFee = parseNumber(json['depositFee'] ?? json['TongTienCoc']);
    int sFee = parseNumber(json['shippingFee'] ?? json['shipping_fee'] ?? json['PhiGiaoHang']);
    int calculatedTotal = rFee + dFee + sFee;

    return Order(
      id: parseNumber(json['id'] ?? json['MaDonThue']),
      userId: parseNumber(json['userId'] ?? json['user_id'] ?? json['MaKhachThue']),
      rentalFee: rFee,
      depositFee: dFee,
      shippingFee: sFee,
      totalPrice: parseNumber(json['totalPrice'] ?? json['total_money'] ?? json['total_price']) > 0
          ? parseNumber(json['totalPrice'] ?? json['total_money'] ?? json['total_price'])
          : calculatedTotal,
      status: json['status'] ?? json['TrangThaiDon'] ?? "pending",
      createdAt: json['createdAt'] ?? json['created_at'] ?? json['NgayTao'] ?? "",
      fullName: json['fullName'] ?? json['full_name'] ?? json['HoTen'], 
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? json['SoDienThoai'],
      couponId: json['coupon_id'] != null ? parseNumber(json['coupon_id']) : null,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      address: fullAddress,
      items: itemsList ?? [],
    );
  }
}