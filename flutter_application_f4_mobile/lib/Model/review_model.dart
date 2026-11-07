// 1. Class Item chi tiết (Tương ứng với từng object trong 'rows')
class ReviewItem {
  final double rating;
  final String comment;
  final String fullname;
  final DateTime? createdAt;

  ReviewItem({
    required this.rating,
    required this.comment,
    required this.fullname,
    this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      // Chuyển đổi an toàn sang double (vì server có thể trả về 5 hoặc 5.0)
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      comment: json['comment'] ?? "",
      fullname: json['fullname'] ?? "Ẩn danh",
      // Parse ngày tháng chuẩn ISO
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
}

// 2. Class chứa thông tin thống kê (Tương ứng với key 'reviews')
class ReviewData {
  final int totalRating;
  final double avgRating;
  final List<ReviewItem> rows;

  ReviewData({
    required this.totalRating,
    required this.avgRating,
    required this.rows,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      totalRating: int.tryParse(json['totalRating'].toString()) ?? 0,
      avgRating: double.tryParse(json['avgRating'].toString()) ?? 0.0,
      rows: (json['rows'] as List? ?? [])
          .map((item) => ReviewItem.fromJson(item))
          .toList(),
    );
  }
}

// 3. Class ngoài cùng (Response tổng từ API)
class ReviewResponse {
  final bool succeeded;
  final String message;
  final ReviewData? data;

  ReviewResponse({
    required this.succeeded,
    required this.message,
    this.data,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      succeeded: json['succeeded'] ?? false,
      message: json['message'] ?? "",
      // Key trong JSON là "reviews", nhưng ta map vào biến 'data' cho dễ hiểu
      data: json['reviews'] != null ? ReviewData.fromJson(json['reviews']) : null,
    );
  }
}