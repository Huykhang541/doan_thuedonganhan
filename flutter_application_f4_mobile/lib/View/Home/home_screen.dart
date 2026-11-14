import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Controller/brandsController.dart';
import '../../Controller/product_controller.dart';
import '../../Controller/cart_Controller.dart';
import '../../Model/product_model.dart';
import '../../Model/brandsModel.dart';
import '../Category/category_screen.dart';
import '../../View/login_screen.dart';
import '../../View/profile_screen.dart';
import '../../View/shoppingcard_screen.dart';
import '../Category/product_by_category_screen.dart';
import '../Product/product_detail_screen.dart';
import '../Product/all_product_screen.dart';
import '../../Controller/favorite_controller.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _futureCombinedData;
  late Future<List<BrandsModel>> _futureBrands;
  List<Product> _cachedProducts = []; 
  List<ProductVariant> _cachedAllVariants = []; 
  String _searchText = ""; 
  String? _userToken;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, String> _imageHeaders = const { "ngrok-skip-browser-warning": "true" };

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    _futureBrands = BrandsController.getAllBrands();
    _loadData();
  }

  void _loadData() {
    _futureCombinedData = Future.wait([
      ProductController.fetchProducts(),
      ProductController.getAllProductVariants()
    ]).then((data) {
      if (mounted) {
        setState(() {
          if (data[0] is List<Product> && data[1] is List<ProductVariant>) {
             _cachedProducts = data[0] as List<Product>;
             _cachedAllVariants = data[1] as List<ProductVariant>;
          }
        });
      }
      return data;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { setState(() { _userToken = prefs.getString('user_token') ?? ''; }); }
  }

  void _onSearchChanged(String query) { setState(() { _searchText = query.toLowerCase(); }); }

  Future<bool?> _navigateToDetail(int productId) async {
    if (productId > 0) {
      return await Navigator.push<bool>(
        context, 
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId, productVariantId: null))
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool hasText = _searchText.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10), child: _buildHeader()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildSearchBar()),
            const SizedBox(height: 10),
            Expanded(child: hasText ? _buildSearchResultList() : _buildHomeContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/Logo.png', height: 50, width: 50, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.store, size: 40, color: Colors.orange)),
        const Text("F2 CAMPING", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        Row(
          children: [
            IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder:(context) => const ShoppingCardScreen())), icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black)),
            IconButton(
              onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder:(context) => (_userToken != null && _userToken!.isNotEmpty) ? const ProfileScreen() : const LoginScreen())); },
              icon: const Icon(Icons.person_outline, color: Colors.black),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: _searchController, focusNode: _searchFocusNode, textInputAction: TextInputAction.search, onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Bạn tìm gì hôm nay?", hintStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchText.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); _onSearchChanged(""); FocusScope.of(context).unfocus(); }) : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: Colors.orange,
      onRefresh: () async {
        setState(() { _futureBrands = BrandsController.getAllBrands(); _loadData(); });
        await Future.wait([_futureBrands, _futureCombinedData]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildBanner(),
            const SizedBox(height: 20),
            _buildSectionTitle("Danh mục", onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CategoryScreen())); }),
            const SizedBox(height: 10),
            _buildCategoryList(),
            const SizedBox(height: 20),
            _buildSectionTitle(
              "Sản phẩm nổi bật",
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => AllProductsScreen(products: _cachedProducts, variants: _cachedAllVariants))); },
            ),
            const SizedBox(height: 10),
            _buildProductGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultList() {
    final results = _cachedProducts.where((product) => product.name.toLowerCase().contains(_searchText)).toList();
    if (results.isEmpty) return const Center(child: Text("Không tìm thấy sản phẩm nào"));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), itemCount: results.length, separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: SizedBox(width: 60, height: 60, child: product.imageUrl.isNotEmpty ? Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)) : const Icon(Icons.image, size: 40, color: Colors.grey)),
          title: Text(product.name), subtitle: Text(formatCurrency(product.price), style: const TextStyle(color: Colors.red)),
          onTap: () => _navigateToDetail(product.id),
        );
      },
    );
  }

  Widget _buildBanner() {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/images/trangchu1.png', width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.grey[300])));
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [ Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), InkWell(onTap: onTap, child: const Icon(Icons.chevron_right, color: Colors.grey)), ],
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 90, 
      child: FutureBuilder<List<BrandsModel>>(
        future: _futureBrands, 
        builder: (context, snapshot){
           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
           if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
           final brands = snapshot.data!;
           return ListView.separated(
             scrollDirection: Axis.horizontal, itemCount: brands.length, separatorBuilder: (_, __) => const SizedBox(width: 15),
             itemBuilder: (context, index) {
               final cat = brands[index];
               return InkWell(
                 onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProductByCategoryScreen(category_id: cat.id, nameBrands: cat.name))),
                 child: Column(
                   children: [
                     Container(
                       width: 55, height: 55, padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.orange.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3)]),
                       child: cat.image_url.isNotEmpty ? Image.network(cat.image_url, fit: BoxFit.contain) : const Icon(Icons.phone_android),
                     ),
                     const SizedBox(height: 5), Text(cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                   ],
                 )
               );
             },
           );
        }
      )
    );
  }

  Widget _buildProductGrid() {
    return FutureBuilder<List<dynamic>>(
      future: _futureCombinedData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Colors.orange)));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();

        List<Product> listProducts = _cachedProducts;
        Set<int> hotProductIds = {};
        if (listProducts.isNotEmpty) {
           List<Product> sorted = List.from(listProducts)..sort((a, b) => b.soldCount.compareTo(a.soldCount));
           hotProductIds = sorted.take(10).map((p) => p.id).toSet();
        }

        double screenWidth = MediaQuery.of(context).size.width;
        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: screenWidth >= 1200 ? 5 : screenWidth >= 800 ? 4 : 2, childAspectRatio: screenWidth >= 800 ? 0.72 : 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: listProducts.length,
          itemBuilder: (context, index) {
            final product = listProducts[index];
            final defaultVariant = _cachedAllVariants.firstWhere((v) => v.productId == product.id, orElse: () => ProductVariant(id: 0, productId: product.id, price: 0, imageUrl: ''));
            return _HoverProductCard(
              product: product, defaultVariant: defaultVariant, isHot: hotProductIds.contains(product.id),
              imageHeaders: _imageHeaders, onTap: () => _navigateToDetail(product.id), formatCurrency: formatCurrency,
            );
          },
        );
      },
    );
  }
}

class _HoverProductCard extends StatefulWidget {
  final Product product; 
  final ProductVariant defaultVariant; 
  final bool isHot; 
  final Map<String, String> imageHeaders; 
  final Future<bool?> Function() onTap; 
  final Function(double) formatCurrency; 
  
  const _HoverProductCard({ 
    required this.product, 
    required this.defaultVariant, 
    required this.isHot, 
    required this.imageHeaders, 
    required this.onTap, 
    required this.formatCurrency
  });
  
  @override State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _isHovering = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkInitialFavorite();
  }

  void _checkInitialFavorite() async {
    bool status = await FavoriteController.checkIsFavorite(widget.product.id);
    if (mounted) {
      setState(() {
        _isFavorite = status;
      });
    }
  }

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
  
  @override 
  Widget build(BuildContext context) {
    String imgUrl = widget.product.imageUrl;
    double price = widget.product.price;
    double deposit = widget.product.deposit ?? 0.0;
    
    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    bool canRent = false;

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
        onTap: () async {
          final result = await widget.onTap();
          if (result != null) {
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
                            width: double.infinity, 
                            padding: const EdgeInsets.all(12), 
                            color: Colors.white, 
                            child: imgUrl.isNotEmpty 
                              ? Image.network(imgUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey))) 
                              : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                          )
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
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
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
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
                                    // BỔ SUNG: Truyền thêm 1 ngày và tiền cọc
                                    await CartController.addToCart(widget.defaultVariant.id, 1, 1, deposit);
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
              if (widget.isHot) Positioned(top: 0, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(8))), child: const Text("HOT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}