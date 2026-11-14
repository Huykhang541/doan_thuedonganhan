import 'package:flutter/material.dart';
import '../../resources/app_colors.dart';
import '../Model/User.dart';
import '../Controller/auth_controller.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'order_history_screen.dart';
import 'Widget/profile_menu_item.dart';
import 'Home/home_screen.dart';
import'favorite_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- 1. KHAI BÁO BIẾN ---
  final AuthController _authController = AuthController();
  late Future<User?> _userFuture; // Biến chứa dữ liệu User bất đồng bộ

  // --- 2. KHỞI TẠO ---
  @override
  void initState() {
    super.initState();
    _userFuture = _authController.getProfile(); // Gọi API lấy thông tin ngay khi mở
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
      
      // FutureBuilder: Quản lý trạng thái tải dữ liệu
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {

          // Trạng thái đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          // Trạng thái lỗi hoặc chưa đăng nhập
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Lỗi tải thông tin", style: TextStyle(color: Colors.white)),
                  TextButton(
                    onPressed: () {
                        Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (_) => const LoginScreen()), 
                        (route) => false
                      );
                    },
                    child: const Text("Đăng nhập lại", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }
          // Trạng thái thành công -> Lấy dữ liệu
          final User user = snapshot.data!;

          return Column(
            children: [
              // --- HEADER (Avatar + Tên) ---
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.person, size: 75, color: Colors.grey),
                        ),
                        // Chấm xanh online
                        Container(
                          width: 25, height: 25,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.backgroundOrange, width: 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(user.fullname ?? "User", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              // --- MENU CHỨC NĂNG ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Menu: Sửa thông tin
                        ProfileMenuItem(
                          icon: Icons.person_outline,
                          text: "Chỉnh sửa thông tin",
                          onTap: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => EditProfileScreen(currentUser: user))
                            );
                            // Nếu sửa xong -> Load lại API
                            if (result == true) setState(() => _userFuture = _authController.getProfile());
                          },
                        ),

                        // =========================================================
                        // --- BẮT ĐẦU ĐOẠN CODE THÊM MỚI: NÚT NÂNG CẤP TÀI KHOẢN ---
                        // =========================================================
                        if (user.role != 'ca_hai' && user.role != 'admin' && user.role != 'Admin')
                          ProfileMenuItem(
                            icon: Icons.star_border, 
                            textColor: Colors.orange, // Làm nổi bật nút nâng cấp
                            text: user.role == 'khach_hang' 
                                ? "Đăng ký trở thành Chủ cho thuê" 
                                : "Đăng ký trở thành Khách thuê",
                            onTap: () async {
                              // 1. Hiện hộp thoại xác nhận
                              bool confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text("Bạn có muốn mở khóa tính năng để vừa có thể thuê đồ, vừa có thể cho thuê đồ của mình không?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false), 
                                      child: const Text("Hủy", style: TextStyle(color: Colors.grey))
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true), 
                                      child: const Text("Đồng ý", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                                    ),
                                  ],
                                )
                              ) ?? false;

                              // 2. Nếu Đồng ý -> Gọi API nâng cấp
                              if (confirm) {
                                bool success = await _authController.upgradeRole(context);
                                if (success) {
                                  // Nâng cấp thành công -> Tải lại Profile để ẩn nút này đi
                                  setState(() => _userFuture = _authController.getProfile());
                                }
                              }
                            },
                          ),
                        // =========================================================
                        // --- KẾT THÚC ĐOẠN CODE THÊM MỚI ---
                        // =========================================================
                        
                        // Menu: Đổi mật khẩu
                        ProfileMenuItem(
                          icon: Icons.lock_outline,
                          text: "Đổi mật khẩu",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                        ),

                        // Menu: Danh sách yêu thích
                        ProfileMenuItem(
                          icon: Icons.favorite_outline, 
                          text: "Danh sách yêu thích", 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                            );
                          }
                        ),
                        
                        // Menu: Lịch sử đơn hàng
                        ProfileMenuItem(
                          icon: Icons.card_giftcard, 
                          text: "Lịch sử đơn hàng", 
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                        ),

                        // Menu: Đăng xuất
                        ProfileMenuItem(
                          icon: Icons.logout,
                          text: "Đăng xuất",
                          textColor: Colors.red,
                          isLast: true,
                          onTap: () async {
                            await _authController.logout(); // Xóa token
                            if (context.mounted) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}