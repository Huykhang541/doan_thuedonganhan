import 'package:flutter/material.dart';
import '../../resources/app_colors.dart';
import 'Widget/custom_button.dart';
import 'Widget/custom_textfield.dart';
import '../Controller/auth_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // --- 1. KHAI BÁO BIẾN ---
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  final AuthController _authController = AuthController();
  bool _isLoading = false; // Biến trạng thái loading

  // Giải phóng bộ nhớ khi tắt màn hình
  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- 2. XỬ LÝ LOGIC ---
  Future<void> _handleChangePassword() async {
    // B1: Kiểm tra rỗng
    if (_oldPassController.text.isEmpty || 
        _newPassController.text.isEmpty || 
        _confirmPassController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Vui lòng nhập đủ các trường"), backgroundColor: Colors.red),
       );
       return;
    }

    // B2: Kiểm tra mật khẩu xác nhận có khớp không
    if (_newPassController.text != _confirmPassController.text) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Mật khẩu xác nhận không khớp"), backgroundColor: Colors.red),
       );
       return;
    }

    // B3: Kiểm tra mật khẩu mới có trùng mật khẩu cũ không
    if (_oldPassController.text == _newPassController.text) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Mật khẩu mới không được trùng với mật khẩu cũ"), backgroundColor: Colors.red),
       );
       return;
    }

    // B4: Gọi API đổi mật khẩu
    setState(() => _isLoading = true); // Hiện loading

    await _authController.changePassword(
      context, 
      currentPassword: _oldPassController.text, 
      newPassword: _newPassController.text
    );

    if (mounted) {
      setState(() => _isLoading = false); // Tắt loading
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
          onPressed: () => Navigator.pop(context), // Nút quay lại
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20), 
          // Khung form màu trắng
          child: Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text("Đổi mật khẩu", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 30),

                // Các ô nhập liệu
                CustomTextField(
                  label: "Mật khẩu cũ", 
                  hint: "*******", 
                  controller: _oldPassController, 
                  isPassword: true
                ),
                CustomTextField(
                  label: "Mật khẩu mới", 
                  hint: "*******", 
                  controller: _newPassController, 
                  isPassword: true
                ),
                CustomTextField(
                  label: "Xác nhận mật khẩu mới", 
                  hint: "*******", 
                  controller: _confirmPassController, 
                  isPassword: true
                ),

                const SizedBox(height: 20),
                
                // Nút bấm Cập nhật
                CustomButton(
                  text: _isLoading ? "Đang xử lý..." : "Cập nhật", 
                  onPressed: _isLoading ? () {} : _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}