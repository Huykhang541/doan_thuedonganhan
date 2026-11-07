

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../Controller/cart_Controller.dart';
// import '../../Controller/product_controller.dart';
// import '../../Model/product_model.dart';
// import '../Product/product_detail_screen.dart';

// class ProductByCategoryScreen extends StatefulWidget {
//   final int category_id;
//   final String nameBrands;
//   const ProductByCategoryScreen({super.key, required this.category_id, required this.nameBrands});
//   @override State<ProductByCategoryScreen> createState() => _ProductByCategoryScreenState();
// }

// class _ProductByCategoryScreenState extends State<ProductByCategoryScreen> {
//   List<Product> categoryProducts = [];
//   List<ProductVariant> allVariants = [];
//   bool _isPageLoading = false;
//   final Map<String, String> _imageHeaders = const { "ngrok-skip-browser-warning": "true" };

//   @override void initState() { super.initState(); getProducts(); }

//   String formatCurrency(double price) {
//     final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
//     return format.format(price);
//   }

//   Future<void> getProducts() async {
//     setState(() => _isPageLoading = true);
//     // Tải song song cả sản phẩm theo danh mục và tất cả biến thể (để mồi giỏ hàng)
//     final results = await Future.wait([
//       ProductController.getProductsByCategory(widget.category_id),
//       ProductController.getAllProductVariants(),
//     ]);
//     if (!mounted) return;
//     setState(() {
//       categoryProducts = results[0] as List<Product>;
//       allVariants = results[1] as List<ProductVariant>;
//       _isPageLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: BackButton(color: Colors.black, onPressed: () => Navigator.of(context).pop()), title: Text(widget.nameBrands, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), centerTitle: true),
//       body: _isPageLoading ? const Center(child: CircularProgressIndicator()) : categoryProducts.isEmpty ? const Center(child: Text("Không có sản phẩm nào thuộc danh mục này")) : GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2, childAspectRatio: screenWidth >= 800 ? 0.72 : 0.70, crossAxisSpacing: 12, mainAxisSpacing: 12),
//         itemCount: categoryProducts.length,
//         itemBuilder: (context, index) {
//           final product = categoryProducts[index];
//           final defaultVariant = allVariants.firstWhere((v) => v.productId == product.id, orElse: () => ProductVariant(id: 0, productId: product.id, price: 0, imageUrl: ''));
//           return _HoverProductCard(product: product, defaultVariant: defaultVariant, imageHeaders: _imageHeaders, formatCurrency: formatCurrency);
//         },
//       ),
//     );
//   }
// }

// class _HoverProductCard extends StatefulWidget {
//   final Product product; final ProductVariant defaultVariant; final Map<String, String> imageHeaders; final Function(double) formatCurrency;
//   const _HoverProductCard({ required this.product, required this.defaultVariant, required this.imageHeaders, required this.formatCurrency });
//   @override State<_HoverProductCard> createState() => _HoverProductCardState();
// }

// class _HoverProductCardState extends State<_HoverProductCard> {
//   bool _isHovering = false;
//   @override Widget build(BuildContext context) {
//     String imgUrl = widget.product.imageUrl;
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovering = true), onExit: (_) => setState(() => _isHovering = false), cursor: SystemMouseCursors.click,
//       child: GestureDetector(
//         onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: widget.product.id, productVariantId: null))); },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _isHovering ? Colors.black : Colors.grey.shade200, width: _isHovering ? 1.5 : 1), boxShadow: [BoxShadow(color: _isHovering ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.1), blurRadius: _isHovering ? 10 : 5, offset: const Offset(0, 4))]),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.white, child: imgUrl.isNotEmpty ? Image.network(imgUrl, headers: widget.imageHeaders, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))) : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))))),
//               Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(widget.formatCurrency(widget.product.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
//                         InkWell(
//                           onTap: () async {    
//                              if (widget.defaultVariant.id > 0) {
//                                 await CartController.addToCart(widget.defaultVariant.id, 1);
//                                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm ${widget.product.name} vào giỏ"), duration: const Duration(seconds: 1)));
//                              }
//                           },
//                           child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _isHovering ? Colors.black : Colors.white, shape: BoxShape.circle, border: Border.all(color: _isHovering ? Colors.black : Colors.orange)), child: Icon(Icons.add_shopping_cart, size: 18, color: _isHovering ? Colors.white : Colors.orange)),
//                         )
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Controller/product_controller.dart';
import '../../Controller/cart_Controller.dart';
import '../../Controller/favorite_controller.dart';
import '../../Model/product_model.dart';
import '../Product/product_detail_screen.dart';
import '../shoppingcard_screen.dart';

class ProductByCategoryScreen extends StatefulWidget {
  final int category_id;
  final String nameBrands;

  const ProductByCategoryScreen({
    super.key,
    required this.category_id,
    required this.nameBrands,
  });

  @override
  State<ProductByCategoryScreen> createState() => _ProductByCategoryScreenState();
}

class _ProductByCategoryScreenState extends State<ProductByCategoryScreen> {
  late Future<List<dynamic>> _futureData;
  List<Product> _products = [];
  List<ProductVariant> _variants = [];

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _futureData = Future.wait([
      ProductController.getProductsByCategory(widget.category_id),
      ProductController.getAllProductVariants()
    ]).then((data) {
      if (mounted) {
        setState(() {
          _products = data[0] as List<Product>;
          _variants = data[1] as List<ProductVariant>;
        });
      }
      return data;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.nameBrands,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ShoppingCardScreen()));
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || _products.isEmpty) {
            return const Center(child: Text("Không có sản phẩm nào trong danh mục này."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2, 
              childAspectRatio: screenWidth >= 800 ? 0.72 : 0.75, 
              crossAxisSpacing: 12, 
              mainAxisSpacing: 12
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final defaultVariant = _variants.firstWhere(
                (v) => v.productId == product.id, 
                orElse: () => ProductVariant(id: 0, productId: product.id, price: 0, imageUrl: '')
              );

              return _HoverProductCard(
                product: product, 
                defaultVariant: defaultVariant, 
                formatCurrency: formatCurrency,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: product.id, productVariantId: null)
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Giữ nguyên logic Card của trang Home sang đây
class _HoverProductCard extends StatefulWidget {
  final Product product; 
  final ProductVariant defaultVariant; 
  final VoidCallback onTap; 
  final Function(double) formatCurrency; 
  
  const _HoverProductCard({ required this.product, required this.defaultVariant, required this.onTap, required this.formatCurrency});
  
  @override 
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _isHovering = false;
  bool _isFavorite = false;

  void _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    if (_isFavorite) {
      bool success = await FavoriteController.addFavorite(widget.product.id);
      if (!success && mounted) {
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yêu cầu đăng nhập hoặc lỗi kết nối")));
      }
    } else {
      bool success = await FavoriteController.removeFavorite(widget.product.id);
      if (!success) setState(() => _isFavorite = true);
    }
  }
  
  @override 
  Widget build(BuildContext context) {
    String imgUrl = widget.product.imageUrl;
    double price = widget.product.price;
    
    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    bool canRent = false;

    switch (widget.product.status) {
      case 'SanSang':
        statusText = "Còn hàng"; statusBgColor = Colors.green.shade50; statusTextColor = Colors.green.shade700; canRent = true; break;
      case 'ChoDuyet':
        statusText = "Chờ duyệt"; statusBgColor = Colors.orange.shade50; statusTextColor = Colors.orange.shade700; break;
      case 'TamNgung':
        statusText = "Tạm ngưng"; statusBgColor = Colors.grey.shade200; statusTextColor = Colors.grey.shade700; break;
      case 'TuChoi':
        statusText = "Từ chối"; statusBgColor = Colors.red.shade50; statusTextColor = Colors.red.shade700; break;
      default:
        statusText = "Hết hàng"; statusBgColor = Colors.red.shade50; statusTextColor = Colors.red.shade700;
    }
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true), 
      onExit: (_) => setState(() => _isHovering = false), 
      cursor: SystemMouseCursors.click, 
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12), 
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
                            child: imgUrl.isNotEmpty ? Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))) : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                          )
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.grey, size: 22), onPressed: _toggleFavorite),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
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
                                decoration: BoxDecoration(
                                  color: canRent ? (_isHovering ? Colors.black : Colors.white) : Colors.grey.shade200, 
                                  borderRadius: BorderRadius.circular(6), 
                                  border: Border.all(color: canRent ? (_isHovering ? Colors.black : Colors.orange) : Colors.grey.shade300)
                                ), 
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

