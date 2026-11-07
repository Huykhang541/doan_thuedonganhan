/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import Model, Controller và Detail Screen
import '../../Model/product_model.dart';
import '../../Controller/cart_Controller.dart'; 
import '../Product/product_detail_screen.dart';

class AllProductsScreen extends StatelessWidget {
  final List<ProductVariant> products;

  const AllProductsScreen({
    super.key,
    required this.products,
  });

  // Helper format tiền
  String formatCurrency(double? price) {
    if (price == null) return "0₫";
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(price);
  }

  // Header cho ảnh (Fix lỗi ảnh ngrok)
  final Map<String, String> _imageHeaders = const {
    "ngrok-skip-browser-warning": "true",
  };

  @override
  Widget build(BuildContext context) {
    // --- TÍNH TOÁN CỘT (RESPONSIVE) ĐỒNG BỘ VỚI HOME ---
    final screenWidth = MediaQuery.of(context).size.width;

    // Logic số cột: Web to (5), Tablet (4), Mobile (2)
    int crossAxisCount = screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2;
    
    // Tỷ lệ khung hình: Tablet/Web (0.72), Mobile (0.70)
    double childAspectRatio = screenWidth >= 800 ? 0.72 : 0.70;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tất cả sản phẩm", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white, // Đổi sang trắng cho đồng bộ với Home
      body: products.isEmpty
          ? const Center(child: Text("Chưa có sản phẩm nào"))
          : GridView.builder(
              padding: const EdgeInsets.all(16), // Padding giống Home
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12, // Khoảng cách ngang
                mainAxisSpacing: 12,  // Khoảng cách dọc
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final variant = products[index];
                // Gọi Widget Card có hiệu ứng Hover
                return _HoverProductCard(
                  variant: variant,
                  imageHeaders: _imageHeaders,
                  formatCurrency: formatCurrency,
                );
              },
            ),
    );
  }
}

// --- WIDGET CARD MỚI (CÓ HIỆU ỨNG HOVER + VIỀN ĐEN) ---
// Được copy logic từ Home sang để đảm bảo đồng bộ 100%
class _HoverProductCard extends StatefulWidget {
  final ProductVariant variant;
  final Map<String, String> imageHeaders;
  final Function(double?) formatCurrency;

  const _HoverProductCard({
    required this.variant,
    required this.imageHeaders,
    required this.formatCurrency,
  });

  @override
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Bắt sự kiện chuột
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Chuyển trang chi tiết
          if (widget.variant.productId != null) {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: widget.variant.productId!,
                  productVariantId: widget.variant.id,
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // VIỀN: Hover -> Đen, Bình thường -> Xám nhạt
            border: Border.all(
              color: _isHovering ? Colors.black : Colors.grey.shade200, 
              width: _isHovering ? 1.5 : 1
            ),
            // BÓNG: Hover -> Đậm hơn
            boxShadow: [
              BoxShadow(
                color: _isHovering ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                blurRadius: _isHovering ? 10 : 5,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ảnh sản phẩm
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Image.network(
                      widget.variant.imageUrl ?? '',
                      headers: widget.imageHeaders,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
              
              // 2. Thông tin Text
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.variant.name ?? "Sản phẩm", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    if (widget.variant.color != null)
                      Text(widget.variant.color!, style: const TextStyle(fontSize: 11, color: Colors.orange)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.formatCurrency(widget.variant.price), 
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        
                        // Nút giỏ hàng: Hover -> Đen
                        InkWell(
                          onTap: () async {    
                             await CartController.addToCart(widget.variant.id,1);
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                 content: Text("Đã thêm ${widget.variant.name} vào giỏ"), 
                                 duration: const Duration(seconds: 1),
                               ));
                             }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              // Đổi màu nền nút khi Hover Card
                              color: _isHovering ? Colors.black : Colors.white, 
                              shape: BoxShape.circle,
                              border: Border.all(color: _isHovering ? Colors.black : Colors.orange)
                            ),
                            child: Icon(
                              Icons.add_shopping_cart, 
                              size: 18, 
                              // Đổi màu icon
                              color: _isHovering ? Colors.white : Colors.orange
                            ),
                          ),
                        )
                      ],
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
}*/
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Model/product_model.dart';
import '../../Controller/cart_Controller.dart'; 
import '../../Controller/favorite_controller.dart';
import '../Product/product_detail_screen.dart';

class AllProductsScreen extends StatelessWidget {
  final List<Product> products; 
  final List<ProductVariant> variants;

  const AllProductsScreen({
    super.key,
    required this.products,
    required this.variants,
  });

  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(price);
  }

  final Map<String, String> _imageHeaders = const { "ngrok-skip-browser-warning": "true" };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2;
    double childAspectRatio = screenWidth >= 800 ? 0.72 : 0.75; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả sản phẩm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      backgroundColor: Colors.white, 
      body: products.isEmpty
          ? const Center(child: Text("Chưa có sản phẩm nào"))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, 
                childAspectRatio: childAspectRatio, 
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final defaultVariant = variants.firstWhere(
                  (v) => v.productId == product.id, 
                  orElse: () => ProductVariant(id: 0, productId: product.id, price: 0, imageUrl: '')
                );
                return _HoverProductCard(
                  product: product, 
                  defaultVariant: defaultVariant, 
                  imageHeaders: _imageHeaders, 
                  formatCurrency: formatCurrency
                );
              },
            ),
    );
  }
}

class _HoverProductCard extends StatefulWidget {
  final Product product; 
  final ProductVariant defaultVariant; 
  final Map<String, String> imageHeaders; 
  final Function(double) formatCurrency;
  
  const _HoverProductCard({ 
    required this.product, 
    required this.defaultVariant, 
    required this.imageHeaders, 
    required this.formatCurrency 
  });
  
  @override 
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _isHovering = false;
  bool _isFavorite = false;

  void _toggleFavorite() async {
    setState(() { _isFavorite = !_isFavorite; });

    if (_isFavorite) {
      bool success = await FavoriteController.addFavorite(widget.product.id);
      if (!success) {
        setState(() => _isFavorite = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yêu cầu đăng nhập hoặc lỗi kết nối")));
      }
    } else {
      bool success = await FavoriteController.removeFavorite(widget.product.id);
      if (!success) {
        setState(() => _isFavorite = true);
      }
    }
  }

  @override Widget build(BuildContext context) {
    String imgUrl = widget.product.imageUrl;
    double price = widget.product.price;
    
    String statusText; Color statusBgColor; Color statusTextColor; bool canRent = false;

    switch (widget.product.status) {
      case 'SanSang':
        statusText = "Còn hàng"; statusBgColor = Colors.green.shade50; statusTextColor = Colors.green.shade700; canRent = true;
        break;
      case 'ChoDuyet':
        statusText = "Chờ duyệt"; statusBgColor = Colors.orange.shade50; statusTextColor = Colors.orange.shade700;
        break;
      case 'TamNgung':
        statusText = "Tạm ngưng"; statusBgColor = Colors.grey.shade200; statusTextColor = Colors.grey.shade700;
        break;
      case 'TuChoi':
        statusText = "Từ chối"; statusBgColor = Colors.red.shade50; statusTextColor = Colors.red.shade700;
        break;
      default:
        statusText = "Hết hàng"; statusBgColor = Colors.red.shade50; statusTextColor = Colors.red.shade700;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true), 
      onExit: (_) => setState(() => _isHovering = false), 
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Cập nhật onTap: Lắng nghe giá trị isFav từ trang chi tiết trả về
        onTap: () async { 
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: widget.product.id, productVariantId: null))
          ); 
          if (result != null && result is bool) {
            setState(() { _isFavorite = result; });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: _isHovering ? Colors.black : Colors.grey.shade200, width: _isHovering ? 1.5 : 1), 
            boxShadow: [BoxShadow(color: _isHovering ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.1), blurRadius: _isHovering ? 10 : 5, offset: const Offset(0, 4))]
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), 
                          child: Container(
                            width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.white, 
                            child: imgUrl.isNotEmpty ? Image.network(imgUrl, headers: widget.imageHeaders, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))) : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                          )
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: IconButton(
                            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.grey, size: 22),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                      ],
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4),
                                Text("${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.reviewCount})", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(4)),
                              child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.formatCurrency(price).replaceAll('₫', 'VNĐ'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text("/ ngày", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                            InkWell(
                              onTap: canRent ? () async {    
                                 if (widget.defaultVariant.id > 0) {
                                    await CartController.addToCart(widget.defaultVariant.id, 1);
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${widget.product.name} vào giỏ"), duration: const Duration(seconds: 1)));
                                 }
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
                                decoration: BoxDecoration(color: canRent ? (_isHovering ? Colors.black : Colors.white) : Colors.grey.shade200, borderRadius: BorderRadius.circular(6), border: Border.all(color: canRent ? (_isHovering ? Colors.black : Colors.orange) : Colors.grey.shade300)), 
                                child: Text("Thuê ngay", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: canRent ? (_isHovering ? Colors.white : Colors.orange) : Colors.grey.shade500))
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}