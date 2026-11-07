import 'package:flutter/material.dart';
import '../../Resources/app_colors.dart';
import 'Widget/custom_button.dart';
import 'Widget/custom_textfield.dart';
import 'signup_screen.dart';
import '../Controller/auth_controller.dart';
import 'Home/home_screen.dart';
import 'Admin/admin_order_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 1. KHAI BÁO BIẾN ---
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final AuthController _authController = AuthController();
  
  bool _isLoading = false; // Biến trạng thái loading

  // Giải phóng bộ nhớ khi tắt màn hình
  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- 2. XỬ LÝ LOGIC ---
  void _handleLogin() async {
    String email = _emailController.text.trim();
    String pass = _passController.text.trim();

    // B1: Kiểm tra rỗng
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Email và Mật khẩu"), backgroundColor: Colors.red),
      );
      return;
    }

    // B2: Gọi API Đăng nhập
    setState(() => _isLoading = true); // Hiện loading

    bool isSuccess = await _authController.login(context, email, pass);

    if (mounted) {
      setState(() => _isLoading = false); // Tắt loading

      // B3: Phân quyền
      if (isSuccess) {
        if (email == "admin@gmail.com") {
           // Nếu là Admin -> Vào trang quản lý đơn hàng
           print("👑 Chào mừng Admin!");
           Navigator.pushAndRemoveUntil(
             context, 
             MaterialPageRoute(builder: (_) => const AdminOrderListScreen()), 
             (route) => false
           );
        } else {
           // Nếu là User -> Vào trang chủ
           Navigator.pushAndRemoveUntil(
             context, 
             MaterialPageRoute(builder: (_) => const HomeScreen()),
             (route) => false
           );
        }
      }
    }
  }

  // --- 3. GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOrange,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Quay về trang chủ
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => const HomeScreen())
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset('assets/Logo.png', height: 200, width: 200),
              const SizedBox(height: 20),

              // Khung Form màu trắng
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    const Text("Đăng Nhập", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    // Link chuyển sang Đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                          },
                          child: const Text("Đăng ký", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Các ô nhập liệu
                    CustomTextField(
                      label: "Email", 
                      hint: "Loisbecket@gmail.com", 
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    CustomTextField(
                      label: "Mật khẩu", 
                      hint: "*******", 
                      controller: _passController, 
                      isPassword: true
                    ),
                    const SizedBox(height: 20),

                    // Nút bấm Đăng nhập
                    CustomButton(
                      text: _isLoading ? "Đang xử lý..." : "Đăng Nhập",
                      onPressed: _isLoading ? () {} : _handleLogin,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}