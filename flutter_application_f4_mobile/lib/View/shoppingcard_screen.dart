import 'package:flutter/material.dart';
import '../View/Product/product_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../resources/app_colors.dart';
import '../Model/cartModel.dart'; 
import '../Controller/cart_Controller.dart';
import '../View/Widget/custom_button.dart';
import 'checkout_screen.dart';

class ShoppingCardScreen extends StatefulWidget {
  const ShoppingCardScreen({super.key});

  @override
  State<ShoppingCardScreen> createState() => _ShoppingCardScreenState();
}

class _ShoppingCardScreenState extends State<ShoppingCardScreen> {
  final CartController _cartController = CartController();
  CartResponse? _cartData;
  bool _isLoadingInitial = true;
  String? _userToken;
  
  String formatCurrency(double? amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return format.format(amount ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _firstLoad();
    _loadToken();
  }

  Future<void> _firstLoad() async {
    try {
      final data = await _cartController.getCartData();
      if (mounted) {
        setState(() {
          _cartData = data;
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? '';
    if (mounted) setState(() => _userToken = token);
  }

  Future<void> _refreshCartSilent() async {
    final data = await _cartController.getCartData();
    if (mounted && data != null) setState(() => _cartData = data);
  }

  Future<void> _handleDeleteItem(int index, int variantId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa món đồ này khỏi danh sách thuê?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;
    bool success = await _cartController.deleteCartItem(variantId);

    if (success) {
      setState(() => _cartData!.data.removeAt(index));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa món đồ"), duration: Duration(seconds: 1)));
      _refreshCartSilent();
    }
  }

  Future<void> _handleUpdateQuantity(int index, int variantId, int currentQty, bool isIncrease) async {
    int newQty = isIncrease ? currentQty + 1 : currentQty - 1;
    if (newQty < 1) {
      _handleDeleteItem(index, variantId);
      return;
    }

    setState(() => _cartData!.data[index] = _cartData!.data[index].copyWith(quantity: newQty));
    bool success = await _cartController.updateCartQuantity(variantId, newQty);
    if (success) {
      await _refreshCartSilent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOrange,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(24),
                child: _buildBodyContent(), 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoadingInitial) return const Center(child: CircularProgressIndicator());
    if (_cartData == null || _cartData!.data.isEmpty) {
      return RefreshIndicator(
        onRefresh: _firstLoad,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: const Center(child: Text("Danh sách đồ muốn thuê đang trống")),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _firstLoad,
            child: ListView.separated(
              itemCount: _cartData!.data.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) => _buildCartItem(_cartData!.data[index], index),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterTotal(_cartData!.totalMoney), 
        const SizedBox(height: 16),
        CustomButton(
          text: "Tiếp tục đặt thuê", 
          onPressed: () {
             if (_cartData == null || _cartData!.data.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Danh sách trống!")));
                return;
             }
             if (_userToken != '' && _userToken != null) {
               Navigator.push(
                 context, 
                 MaterialPageRoute(
                   builder: (context) => CheckoutScreen(
                      cartItems: _cartData!.data,             
                      totalMoney: _cartData!.totalMoney,
                      is_buy_now: false,
                   )
                 )
               );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng đăng nhập trước khi đặt thuê đồ'), backgroundColor: Colors.redAccent)
              );
            }
          }
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: item.productId ?? 0, productVariantId: item.productVariantId,))
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  headers: const {"ngrok-skip-browser-warning": "true"},
                  item.imageUrl ?? '',
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[200]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName ?? 'Món đồ', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _handleDeleteItem(index, item.productVariantId ?? 0),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 4.0),
                            child: Icon(Icons.delete_outline, color: Colors.grey, size: 22),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cập nhật phần hiển thị Tiền thuê và Tiền cọc tại đây
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thuê: ${formatCurrency(item.price)}", 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // Đổi 'item.deposit' thành biến chứa giá trị tiền cọc trong CartItem của bạn (vd: item.depositPrice)
                              "Cọc: ${formatCurrency(item.deposit ?? 0)}", 
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey, fontSize: 13)
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => _handleUpdateQuantity(index, item.productVariantId ?? 0, item.quantity ?? 1, false),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.remove, size: 18, color: Colors.black54)),
                              ),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text("${item.quantity ?? 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                              InkWell(
                                onTap: () => _handleUpdateQuantity(index, item.productVariantId ?? 0, item.quantity ?? 1, true),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.add, size: 18, color: AppColors.primaryOrange)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildFooterTotal(double totalMoney) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Tạm tính tổng tiền:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(formatCurrency(totalMoney), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          const Text("Giỏ đồ muốn thuê", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}