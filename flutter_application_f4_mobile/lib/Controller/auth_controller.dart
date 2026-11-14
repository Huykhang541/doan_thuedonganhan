import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/User.dart';
import '../Config/baseUrl.dart';

class AuthController { 

  // --- HÀM ĐĂNG KÝ ---
  // --- HÀM ĐĂNG KÝ (Đã thêm VaiTro) ---
  Future<void> register(BuildContext context, {
    required String email,
    required String password,
    String? fullname,            
    String? phone,           
    String? address,
    String? role, // Thêm tham số role
  }) async {
    final url = Uri.parse('$baseUrl/register');
    print("🌍 Gọi API Đăng ký: $url");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullname ?? '',   
          'phoneNumber': phone ?? '', 
          'address': address ?? '',
          'VaiTro': role ?? 'khach_hang', // Gửi VaiTro lên backend
        }),
      );

      print("Response Code: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        if(!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      } else {
        final errorData = jsonDecode(response.body);
        String message = errorData['message'] ?? "Đăng ký thất bại";
        if(!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối Server!"), backgroundColor: Colors.red),
      );
    }
  }

  // --- HÀM ĐĂNG NHẬP (Đã tách API /admin/login và /login) ---
Future<String?> login(BuildContext context, String email, String password) async {
  // Kiểm tra xem có phải tài khoản admin không để gọi đúng API
  bool isAdmin = email.toLowerCase() == "admin@gmail.com";
  
  // Trỏ đúng endpoint dựa trên tài liệu Swagger
  final endpoint = isAdmin ? '/admin/login' : '/login';
  final url = Uri.parse('$baseUrl$endpoint');
  
  print("🌍 Gọi API Đăng nhập: $url");

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'email': email, 
        'password': password,
      }),
    );
    print("Login Status: ${response.statusCode}");
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      // API của bạn có thể trả về 'succeeded' hoặc không tùy cấu trúc Admin/User
      String token = data['token'];
      
      // Nếu là admin, mặc định role là admin. Nếu là user, lấy role từ data['user']['role']
      String role = isAdmin ? 'admin' : (data['user']['role'] ?? 'khach_hang'); 
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', token);
      await prefs.setString('email', email);
      await prefs.setString('user_role', role);

      if(!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thành công với vai trò: $role"), backgroundColor: Colors.green),
      );
      
      return role; 
    } else {
      String message = data['message'] ?? "Sai Email hoặc mật khẩu";
      if(!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return null;
    }
  } catch (e) {
    print("Lỗi đăng nhập: $e");
    if(!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Không thể kết nối Server"), backgroundColor: Colors.red),
    );
    return null;
  }
}

  // --- HÀM LẤY PROFILE ---
  Future<User?> getProfile() async {
    final url = Uri.parse('$baseUrl/profile');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']); 
      }
    } catch (e) {
      print("Lỗi kết nối Profile: $e");
    }
    return null;
  }
  
  // --- HÀM ĐĂNG XUẤT ---
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    try {
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        );
      }
    } catch (e) {
      print("Lỗi API: $e"); 
    }
    await prefs.remove('user_token');
    await prefs.remove('email');
    return true;
  }

  // --- HÀM SỬA THÔNG TIN PROFILE ---
  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
}) async {
    final url = Uri.parse('$baseUrl/updateprofile'); 
    print("🌍 Đang gọi API Update: $url");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'fullName': fullName,       
          'phoneNumber': phoneNumber, 
          'address': address,
        }),
      );

      print("Update Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
             return true;
        }
      }
      return false;
    } catch (e) {
      print("Lỗi kết nối Update: $e");
      return false;
    }
  }

  //-- HÀM ĐỔI MẬT KHẨU --

Future<void> changePassword(BuildContext context, {
    required String currentPassword,
    required String newPassword
  }) async {
    final url = Uri.parse('$baseUrl/change-password');
    print("🌍 Gọi API Đổi mật khẩu: $url");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hết phiên đăng nhập, vui lòng đăng nhập lại"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'newPassword': newPassword,
          'currentPassword': currentPassword,
        }),
      );

      print("Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Quay về Profile
      } else {
        final errorData = jsonDecode(response.body);      
        String message = errorData['message'] ?? errorData['title'] ?? "Đổi mật khẩu thất bại";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối Server!"), backgroundColor: Colors.red),
      );
    }
}



// --- HÀM NÂNG CẤP TÀI KHOẢN ---
  Future<bool> upgradeRole(BuildContext context) async {
    final url = Uri.parse('$baseUrl/upgrade-role');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? "Nâng cấp thành công!"), backgroundColor: Colors.green),
            );
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Lỗi nâng cấp tài khoản: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối Server!"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
}