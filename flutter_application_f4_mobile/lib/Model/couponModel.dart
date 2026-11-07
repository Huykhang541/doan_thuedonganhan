class CouponModel {
  final int id;
  final String code;
  final String discountType; // "fixed" hoặc "percent"
  final double discountValue;
  final double minOrderValue;
  final double? maxDiscountAmount; // Có thể null
  final DateTime? startDate;
  final DateTime? endDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.maxDiscountAmount,
    this.startDate,
    this.endDate,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  // Factory để tạo object từ JSON
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? 'fixed',
      
      // JSON trả về chuỗi "50000.00", cần parse sang double
      discountValue: double.tryParse(json['discount_value']?.toString() ?? '0') ?? 0.0,
      minOrderValue: double.tryParse(json['min_order_value']?.toString() ?? '0') ?? 0.0,
      
      // Xử lý null cho max_discount_amount
      maxDiscountAmount: json['max_discount_amount'] != null 
          ? double.tryParse(json['max_discount_amount'].toString()) 
          : null,
          
      // Parse ngày tháng
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      
      usageLimit: json['usage_limit'] ?? 0,
      usedCount: json['used_count'] ?? 0,
      
      // Chuyển int (1/0) thành bool
      isActive: (json['is_active'] == 1), 
    );
  }
}