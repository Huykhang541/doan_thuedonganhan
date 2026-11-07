import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Controller/favorite_controller.dart';
import '../../Model/favorite_model.dart';
import '../../View/Product/product_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // Sửa lại kiểu dữ liệu Future để tránh lỗi type mismatch
  late Future<List<FavoriteModel>> _favoriteFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Hàm load dữ liệu đã được xử lý để lấy ra List<FavoriteModel> chính xác
  void _loadFavorites() {
    setState(() {
      _favoriteFuture = _fetchListFavorites();
    });
  }

  Future<List<FavoriteModel>> _fetchListFavorites() async {
    final result = await FavoriteController.fecthFavorite();
    
    // Kiểm tra cấu trúc trả về từ Controller
    if (result != null && result['succeeded'] == true) {
      // Vì controller trả về data dạng Map hoặc Object, ta cần parse cẩn thận
      // Giả sử result['favoriteRespone'] đã là object FavoriteRespone hoặc Map
      var responseData = result['favoriteRespone'];
      
      if (responseData is FavoriteRespone) {
        return responseData.favorites ?? [];
      } else if (responseData is Map<String, dynamic>) {
        // Trường hợp controller chưa parse JSON
        var respObj = FavoriteRespone.fromJson(responseData);
        return respObj.favorites ?? [];
      }
    }
    return [];
  }

  // Hàm format tiền tệ
  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          "SẢN PHẨM YÊU THÍCH",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<FavoriteModel>>(
        future: _favoriteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Danh sách yêu thích trống", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final favorites = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = favorites[index];
              return _buildFavoriteItemCard(item);
            },
          );
        },
      ),
    );
  }

  // --- WIDGET CARD HIỂN THỊ CHI TIẾT SẢN PHẨM ---
  Widget _buildFavoriteItemCard(FavoriteModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Chuyển sang trang chi tiết (dùng productVariantId hoặc id tùy logic của bạn)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: item.productID, // Cần ID gốc nếu có, nếu không thì truyền tạm 0
                productVariantId: item.productID,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ảnh sản phẩm
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade100,
                  child: Image.network(
                    headers: {'ngrok-skip-browser-warning': 'true'},
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, color: Colors.grey);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Thông tin chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Chip hiển thị Màu & Bộ nhớ (Hiển thị đẹp hơn text thường)
                    /*Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (item.color.isNotEmpty)
                          _buildAttributeChip(item.color, Colors.blue.shade50, Colors.blue.shade700),
                        if (item.storage.isNotEmpty)
                          _buildAttributeChip(item.storage, Colors.orange.shade50, Colors.orange.shade800),
                      ],
                    ),*/
                    
                    const SizedBox(height: 8),

                    // Giá tiền
                    Text(
                      formatCurrency(item.price),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Nút xóa (Icon Trash)
              IconButton(
                onPressed: () => _confirmDelete(item.id, item.productID),
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 24),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper tạo chip thuộc tính (Màu/ROM)
  /*Widget _buildAttributeChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }*/

  // Hàm xác nhận xóa
  void _confirmDelete(int favoriteId, int productID) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa khỏi yêu thích?"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này không?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              bool success = await FavoriteController.removeFavorite(productID);
              if (success) {
                _loadFavorites(); // Load lại danh sách
                if(!mounted)return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã xóa thành công"), duration: Duration(seconds: 1), backgroundColor: Colors.green,),
                );
              } else {
                if(!mounted)return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Xóa thất bại"), backgroundColor: Colors.red,),
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}