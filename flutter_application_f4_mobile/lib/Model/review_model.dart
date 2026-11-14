// file: lib/Model/review_model.dart

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
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      comment: json['comment'] ?? "",
      fullname: json['fullname'] ?? "Ẩn danh",
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }
}

// 2. Class chứa thông tin thống kê
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
    var rawRows = json['rows'];
    List<ReviewItem> parsedRows = [];
    if (rawRows is List) {
      parsedRows = rawRows.map((item) => ReviewItem.fromJson(item as Map<String, dynamic>)).toList();
    }

    return ReviewData(
      totalRating: int.tryParse((json['totalRating'] ?? parsedRows.length).toString()) ?? 0,
      avgRating: double.tryParse((json['avgRating'] ?? 0.0).toString()) ?? 0.0,
      rows: parsedRows,
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
    ReviewData? extractedData;
    
    // Ánh xạ với response mẫu của backend: {succeeded: true, message: "...", reviews: {...}}
    if (json['reviews'] != null && json['reviews'] is Map<String, dynamic>) {
        extractedData = ReviewData.fromJson(json['reviews'] as Map<String, dynamic>);
    }

    return ReviewResponse(
      succeeded: json['succeeded'] == true,
      message: json['message'] ?? "",
      data: extractedData,
    );
  }
}