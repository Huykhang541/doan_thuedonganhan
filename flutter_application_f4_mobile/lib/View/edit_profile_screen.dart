import 'package:flutter/material.dart';
import '../../resources/app_colors.dart';
import 'Widget/custom_button.dart';
import 'Widget/custom_textfield.dart';
import '../Controller/auth_controller.dart'; 
import '../Model/User.dart'; 

class EditProfileScreen extends StatefulWidget {
  final User? currentUser; // Nhận dữ liệu user hiện tại từ trang trước
  const EditProfileScreen({super.key, this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- 1. KHAI BÁO BIẾN ---
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  final AuthController _authController = AuthController();
  bool _isLoading = false; // Biến trạng thái loading

  // --- 2. KHỞI TẠO ---
  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu cũ vào các ô input
    // Nếu dữ liệu null thì để chuỗi rỗng ""
    _nameController = TextEditingController(text: widget.currentUser?.fullname ?? "");
    _emailController = TextEditingController(text: widget.currentUser?.email ?? "");
    _phoneController = TextEditingController(text: widget.currentUser?.phone_number ?? "");
    _addressController = TextEditingController(text: widget.currentUser?.address ?? "");
  }

  // Giải phóng bộ nhớ khi tắt màn hình
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- 3. XỬ LÝ LOGIC ---
  Future<void> _handleSave() async {
    // B1: Validate dữ liệu (Tên không được để trống)
    if (_nameController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tên không được để trống"), backgroundColor: Colors.red));
       return;
    }

    setState(() => _isLoading = true); // Hiện loading

    // B2: Gọi API cập nhật thông tin
    bool isSuccess = await _authController.updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    setState(() => _isLoading = false); // Tắt loading

    // B3: Xử lý kết quả trả về
    if (isSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green));
      
      // Đóng màn hình và trả về 'true'
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thất bại"), backgroundColor: Colors.red));
    }
  }

  // --- 4. GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

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
          // Khung Form màu trắng
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
              children: [
                const Center(
                  child: Text(
                    "Chỉnh sửa thông tin",
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Các ô nhập liệu (Email không cho sửa)
                CustomTextField(
                   label: "Email (Không thể sửa)", 
                   hint: user?.email ?? "Email",
                   controller: _emailController,
                   readOnly: true, 
                ),

                CustomTextField(
                  label: "Họ và Tên", 
                  hint: user?.fullname ?? "Nhập tên...",
                  controller: _nameController
                ),

                CustomTextField(
                  label: "Số điện thoại", 
                  hint: user?.phone_number ?? "Nhập sđt...",
                  controller: _phoneController, 
                  keyboardType: TextInputType.phone
                ),

                CustomTextField(
                  label: "Địa chỉ", 
                  hint: user?.address ?? "Nhập địa chỉ...",
                  controller: _addressController
                ),

                const SizedBox(height: 20),
                
                // Nút Lưu thay đổi
                CustomButton(
                  text: _isLoading ? "Đang xử lý..." : "Xác nhận", 
                  onPressed: _isLoading ? () {} : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}