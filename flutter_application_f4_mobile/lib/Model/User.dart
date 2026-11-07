class User {
  final int id;
  final String? password; // Cho phép null vì API profile không trả về mật khẩu
  final String? fullname;
  final String? email;
  final String? phone_number;
  final String? address;
  final bool isAdmin;
  final DateTime? createdAt; // Cho phép null
  final DateTime? updatedAt; // Cho phép null
  final DateTime? deletedAt; // Cho phép null

  User({
    required this.id,
    this.password,
    this.fullname,
    this.email,
    this.phone_number,
    this.address,
    required this.isAdmin,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Dùng ?? để cung cấp giá trị mặc định an toàn nếu backend thiếu dữ liệu
      id: json['id'] as int? ?? 0, 
      password: json['password'] as String?, 
      fullname: json['fullname'] as String?,
      email: json['email'] as String?,
      phone_number: json['phone_number'] as String?,
      address: json['address'] as String?,
      
      // Xử lý is_admin an toàn, tránh lỗi cast type
      isAdmin: (json['is_admin'] as int? ?? 0) == 1, 
      
      // Xử lý DateTime an toàn bằng tryParse
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }
}