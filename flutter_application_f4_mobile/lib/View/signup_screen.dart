import 'package:flutter/material.dart';
import '../../Resources/app_colors.dart';
import 'Widget/custom_button.dart';
import 'Widget/custom_textfield.dart';
import '../Controller/auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --- 1. KHAI BÁO BIẾN ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); 
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  final AuthController _authController = AuthController(); 
  bool _isLoading = false; // Biến để hiện vòng xoay loading

  // Giải phóng bộ nhớ khi tắt màn hình
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- 2. XỬ LÝ LOGIC ---
  void _handleRegister() async{
    // B1: Kiểm tra rỗng
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin"), backgroundColor: Colors.red));
       return;
    }

    // B2: Kiểm tra mật khẩu xác nhận
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp"), backgroundColor: Colors.red));
      return;
    }

    // B3: Gọi API đăng ký
    setState(() => _isLoading = true); // Hiện loading

    await _authController.register(
      context, 
      email: _emailController.text.trim(),
      password: _passController.text,
      fullname: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (mounted) setState(() => _isLoading = false); // Tắt loading
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
          onPressed: () => Navigator.pop(context),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black, blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Đăng Ký", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    // Link quay lại Đăng nhập
                    Row(
                      children: [
                        const Text("Đã có tài khoản? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text("Đăng nhập", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Các ô nhập liệu
                    CustomTextField(
                      label: "Họ tên", 
                      hint: "Nguyễn Văn A", 
                      controller: _nameController
                    ),

                    CustomTextField(
                      label: "Email", 
                      hint: "abc@gmail.com", 
                      controller: _emailController, 
                      keyboardType: TextInputType.emailAddress
                    ),

                    CustomTextField(
                      label: "SĐT", 
                      hint: "0909...", 
                      controller: _phoneController, 
                      keyboardType: TextInputType.phone
                    ),

                    CustomTextField(
                      label: "Địa chỉ", 
                      hint: "TP.HCM", 
                      controller: _addressController
                    ),

                    CustomTextField(
                      label: "Mật khẩu", 
                      hint: "*******", 
                      controller: _passController, 
                      isPassword: true
                    ),

                    CustomTextField(
                      label: "Nhập lại mật khẩu", 
                      hint: "*******", 
                      controller: _confirmPassController, 
                      isPassword: true
                    ),

                    const SizedBox(height: 20),
                    
                    // Nút bấm Đăng ký
                    CustomButton(
                      text: _isLoading ? "Đang xử lý..." : "Đăng ký", 
                      onPressed: _isLoading ? () {} : _handleRegister,
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