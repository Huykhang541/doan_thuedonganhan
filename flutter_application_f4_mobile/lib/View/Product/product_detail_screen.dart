import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../Controller/product_controller.dart';
import '../../Controller/favorite_controller.dart';
import '../../Controller/cart_Controller.dart';
import '../../Model/product_model.dart';
import '../../Model/review_model.dart';
import '../../Config/baseUrl.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final int? productVariantId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productVariantId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _productFuture;
  late Future<ReviewData?> _reviewsFuture;
  
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5.0;
  bool _isSendingComment = false;

  ProductVariant? _selectedVariant;
  int qty = 1; 
  bool isFav = false;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));

  final Map<String, String> _imageHeaders = const {
    "ngrok-skip-browser-warning": "true",
  };

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return "https://via.placeholder.com/300";
    if (path.startsWith("http")) return path;
    String rootUrl = baseUrl.endsWith('/api') ? baseUrl.replaceAll('/api', '') : baseUrl;
    String cleanBase = rootUrl.endsWith('/') ? rootUrl.substring(0, rootUrl.length - 1) : rootUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return "$cleanBase$cleanPath";
  }

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _productFuture = ProductController.getProductDetail(widget.productId);
    _reviewsFuture = ProductController.getReviews(widget.productId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');

    if (token == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn cần đăng nhập để bình luận!")));
      return;
    }

    setState(() => _isSendingComment = true);
    bool success = await ProductController.postReview(widget.productId, _commentController.text, _userRating);

    if (mounted) {
      setState(() => _isSendingComment = false);
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        setState(() { _reviewsFuture = ProductController.getReviews(widget.productId); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi đánh giá thành công!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi thất bại! Vui lòng thử lại."), backgroundColor: Colors.red));
      }
    }
  }

  // Đồng bộ format giá giống Home
  String formatCurrency(double? price) {
    if (price == null) return "0 VNĐ";
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);
    return format.format(price);
  }

  void _checkFavoriteStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');
    if (token == null || token.isEmpty) return; 
    bool status = await FavoriteController.checkIsFavorite(widget.productId);
    if (mounted) setState(() { isFav = status; });
  }

  void _onFavoritePressed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');
    if (token == null || token.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập để lưu yêu thích!")));
      return;
    }

    bool oldStatus = isFav;
    setState(() { isFav = !isFav; }); 

    bool success;
    if (oldStatus == false) {
      success = await FavoriteController.addFavorite(widget.productId);
    } else {
      success = await FavoriteController.removeFavorite(widget.productId);
    }
    
    if (!success) {
      setState(() { isFav = oldStatus; }); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thất bại, vui lòng thử lại."), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: Colors.black87)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
   DateTime start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day);
    int rentalDays = end.difference(start).inDays;
    
    if (rentalDays <= 0) rentalDays = 1;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, isFav); // Giữ nguyên logic trả tim về
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: FutureBuilder<Product?>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
              else if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text("Không tìm thấy thông tin sản phẩm"));

              final Product product = snapshot.data!;
              final List<ProductVariant> variants = product.variants ?? [];

              if (variants.isEmpty) {
                 return Scaffold(
                   appBar: AppBar(
                     title: Text(product.name), 
                     leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, isFav))
                   ), 
                   body: const Center(child: Text("Sản phẩm chưa có tùy chọn nào."))
                 );
              }

              if (_selectedVariant == null) {
                 if (widget.productVariantId != null) {
                    try { _selectedVariant = variants.firstWhere((v) => v.id == widget.productVariantId); } 
                    catch (e) { _selectedVariant = variants[0]; }
                 } else { _selectedVariant = variants[0]; }
              }

              final displayVariant = _selectedVariant ?? variants[0];
              String displayImage = getFullImageUrl(displayVariant.imageUrl);
              
              double displayPrice = (displayVariant.price != null && displayVariant.price! > 0) ? displayVariant.price! : product.price;
              double displayDeposit = (displayVariant.deposit != null && displayVariant.deposit! > 0) ? displayVariant.deposit! : (product.deposit ?? 0);
              
              String statusText;
              Color statusBgColor;
              Color statusTextColor;
              bool canRent = false;

              switch (product.status) {
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

              return Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0, height: size.height * 0.45,
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Image.network(displayImage, headers: _imageHeaders, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleButton(Icons.arrow_back_ios_new, () => Navigator.pop(context, isFav)),
                        _circleButton(isFav ? Icons.favorite : Icons.favorite_border, _onFavoritePressed, color: isFav ? Colors.red : Colors.grey.shade700),
                      ],
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.4, left: 0, right: 0, bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                            const SizedBox(height: 20),
                            
                            // Tiêu đề + Trạng thái
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(displayVariant.name ?? product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3))),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusText, style: TextStyle(color: statusTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Rating đồng bộ giống Home
                            FutureBuilder<ReviewData?>(
                              future: _reviewsFuture,
                              builder: (context, reviewSnap) {
                                double rating = product.averageRating;
                                int count = product.reviewCount;
                                if (reviewSnap.hasData && reviewSnap.data != null) {
                                  final rData = reviewSnap.data!;
                                  if (rating == 0 && rData.rows.isNotEmpty) {
                                    double sum = 0;
                                    for (var r in rData.rows) sum += r.rating;
                                    rating = sum / rData.rows.length;
                                    count = rData.rows.length;
                                  }
                                }
                                return Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text("${rating.toStringAsFixed(1)} ($count đánh giá)", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                );
                              }
                            ),
                            const SizedBox(height: 16),

                            // Giá và Tiền cọc
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Giá thuê / ngày", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    Text(formatCurrency(displayPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Tiền cọc", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    Text(formatCurrency(displayDeposit), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            const Text("Màu sắc", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (variants.length > 1) ...[
                              Wrap(
                                spacing: 10, runSpacing: 10,
                                children: List.generate(variants.length, (index) {
                                  final variant = variants[index];
                                  final isSelected = _selectedVariant?.id == variant.id;
                                  return GestureDetector(
                                    onTap: () => setState(() { _selectedVariant = variant; qty = 1; }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.orange : Colors.white, 
                                        borderRadius: BorderRadius.circular(20), 
                                        border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300)
                                      ),
                                      child: Text("${variant.color ?? 'Tùy chọn ${index + 1}'}", style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                    ),
                                  );
                                }),
                              ),
                            ] else ...[
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                                  child: Text(displayVariant.color ?? 'Tiêu chuẩn', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            const SizedBox(height: 24),
                            
                            // Chọn ngày
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, true),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Ngày bắt đầu thuê:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, false),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Ngày kết thúc thuê:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(DateFormat('dd/MM/yyyy').format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(displayVariant.description ?? product.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5), textAlign: TextAlign.justify),
                            
                            const SizedBox(height: 30),
                            const Divider(thickness: 4, color: Color(0xFFEEEEEE)),
                            const SizedBox(height: 20),
                            
                            // Đánh giá
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Đánh giá", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Xem tất cả", style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            FutureBuilder<ReviewData?>(
                              future: _reviewsFuture,
                              builder: (context, reviewSnap) {
                                double rating = product.averageRating;
                                if (reviewSnap.hasData && reviewSnap.data != null) {
                                  final rData = reviewSnap.data!;
                                  if (rating == 0 && rData.rows.isNotEmpty) {
                                    double sum = 0;
                                    for (var r in rData.rows) sum += r.rating;
                                    rating = sum / rData.rows.length;
                                  }
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      // CHỈNH SỬA TẠI ĐÂY: Hiển thị nửa sao nếu có phần thập phân
                                      child: Row(
                                        children: List.generate(5, (index) {
                                          if (index < rating.floor()) {
                                            return const Icon(Icons.star, size: 20, color: Colors.amber);
                                          } else if (index == rating.floor() && (rating - rating.floor()) > 0) {
                                            return const Icon(Icons.star_half, size: 20, color: Colors.amber);
                                          } else {
                                            return Icon(Icons.star, size: 20, color: Colors.grey.shade300);
                                          }
                                        }),
                                      ),
                                    )
                                  ],
                                );
                              }
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Viết đánh giá của bạn:", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return IconButton(
                                        icon: Icon(index < _userRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 24),
                                        onPressed: () => setState(() => _userRating = index + 1.0),
                                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                      );
                                    }),
                                  ),
                                  TextField(controller: _commentController, decoration: const InputDecoration(hintText: "Cảm nhận của bạn...", border: InputBorder.none, isDense: true), maxLines: 2, style: const TextStyle(fontSize: 13)),
                                  const Divider(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: _isSendingComment ? null : _submitReview,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(80, 36), elevation: 0),
                                      child: _isSendingComment ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Gửi", style: TextStyle(color: Colors.white)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<ReviewData?>(
                              future: _reviewsFuture, 
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                                final reviewData = snapshot.data;
                                if (reviewData == null || reviewData.rows.isEmpty) return const Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey, fontSize: 13));
                                return ListView.separated(
                                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: reviewData.rows.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final review = reviewData.rows[index];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade200, backgroundImage: const NetworkImage("https://via.placeholder.com/150")),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(review.fullname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  if (review.createdAt != null) Text(DateFormat('dd/MM/yyyy').format(review.createdAt!), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              // Bạn cũng có thể áp dụng sao rưỡi cho từng comment ở đây nếu thích, nhưng thường số sao đánh giá là số nguyên
                                              Row(children: List.generate(5, (s) => Icon(Icons.star, size: 12, color: s < review.rating ? Colors.amber : Colors.grey.shade300))),
                                              const SizedBox(height: 4),
                                              Text(review.comment, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                            ],
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Footer
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Tổng tiền:", style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(formatCurrency(((displayPrice * rentalDays) + displayDeposit) * qty), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                                Text("($qty SP × $rentalDays ngày + Cọc)", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18)),
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Row(
                                    children: [
                                      _qtyBtn(Icons.remove, () { if (qty > 1) setState(() => qty--); }),
                                      SizedBox(width: 16, child: Center(child: Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                      _qtyBtn(Icons.add, () { if (qty < 10) setState(() => qty++); }),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: canRent ? () async {
                                    if (_selectedVariant != null) {
                                      await CartController.addToCart(_selectedVariant!.id, qty);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã thêm $qty ${product.name} vào giỏ"), backgroundColor: Colors.green));
                                    }
                                  } : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canRent ? Colors.orange : Colors.grey.shade300, 
                                    foregroundColor: Colors.white, 
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    elevation: 0
                                  ),
                                  child: Text(canRent ? "Thuê ngay" : statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: canRent ? Colors.white : Colors.grey.shade600)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed, {Color color = Colors.black}) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]), 
      child: IconButton(icon: Icon(icon, color: color, size: 18), onPressed: onPressed, constraints: const BoxConstraints(), padding: const EdgeInsets.all(8))
    );
  }
}