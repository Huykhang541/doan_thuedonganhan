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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); 
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  final AuthController _authController = AuthController(); 
  bool _isLoading = false; 
  
  // BIẾN LƯU VAI TRÒ CHỌN
  String _selectedRole = 'khach_hang'; 

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

  void _handleRegister() async{
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin"), backgroundColor: Colors.red));
       return;
    }

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true); 

    await _authController.register(
      context, 
      email: _emailController.text.trim(),
      password: _passController.text,
      fullname: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      role: _selectedRole, // Truyền vai trò xuống Controller
    );

    if (mounted) setState(() => _isLoading = false); 
  }

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
              Image.asset('assets/Logo.png', height: 200, width: 200),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Đăng Ký", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
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

                    CustomTextField(label: "Họ tên", hint: "Nguyễn Văn A", controller: _nameController),
                    CustomTextField(label: "Email", hint: "abc@gmail.com", controller: _emailController, keyboardType: TextInputType.emailAddress),
                    CustomTextField(label: "SĐT", hint: "0909...", controller: _phoneController, keyboardType: TextInputType.phone),
                    CustomTextField(label: "Địa chỉ", hint: "TP.HCM", controller: _addressController),
                    
                    // --- THÊM DROPDOWN CHỌN VAI TRÒ ---
                    const SizedBox(height: 15),
                    const Text("Bạn là:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    // Sửa đổi từ 'chu_tro' -> 'chu_so_huu'
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'khach_hang', child: Text("Khách cần thuê")),
                        DropdownMenuItem(value: 'chu_do', child: Text("Chủ cho thuê")), // Cập nhật đúng Enum DB
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),


                    const SizedBox(height: 15),
                    // ----------------------------------

                    CustomTextField(label: "Mật khẩu", hint: "*******", controller: _passController, isPassword: true),
                    CustomTextField(label: "Nhập lại mật khẩu", hint: "*******", controller: _confirmPassController, isPassword: true),

                    const SizedBox(height: 20),
                    
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