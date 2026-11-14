class User {
  final int id;
  final String? password; 
  final String? fullname;
  final String? email;
  final String? phone_number;
  final String? address;
  final String? role; // Bổ sung role gốc từ DB
  final bool isAdmin;
  final DateTime? createdAt; 
  final DateTime? updatedAt; 
  final DateTime? deletedAt; 

  User({
    required this.id,
    this.password,
    this.fullname,
    this.email,
    this.phone_number,
    this.address,
    this.role, // Bổ sung
    required this.isAdmin,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0, 
      password: json['password'] as String?, 
      fullname: json['fullname'] as String?,
      email: json['email'] as String?,
      phone_number: json['phone_number'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String?, // Ánh xạ role
      
      isAdmin: (json['is_admin'] as int? ?? 0) == 1, 
      
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