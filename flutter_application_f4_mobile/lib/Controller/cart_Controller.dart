import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/cartModel.dart';
import '../Config/baseUrl.dart';

class CartController {

  // --- 1. LẤY GIỎ HÀNG (CHỈ TỪ LOCAL) ---
  Future<CartResponse?> getCartData() async {
    final prefs = await SharedPreferences.getInstance();
    String? localCartJson = prefs.getString('local_cart');

    if (localCartJson == null || localCartJson.isEmpty) {
      return CartResponse(succeeded: true, data: [], totalMoney: 0);
    }

    List<dynamic> localList = [];
    try {
      localList = jsonDecode(localCartJson);
    } catch (e) {
      return CartResponse(succeeded: true, data: [], totalMoney: 0);
    }

    // Gọi API lấy danh sách biến thể (sản phẩm) để tra cứu thông tin giá, tên
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/products/product-variants/get-all'),
          headers: {"ngrok-skip-browser-warning": "true"}  
      );

      if (response.statusCode == 200) {
        final serverData = jsonDecode(response.body);
        
        if (serverData['succeeded'] == true) {
          List<dynamic> allVariants = serverData['product_variants'];
          List<CartItem> finalCartItems = [];
          double tempTotalMoney = 0.0;

          for (var localItem in localList) {
            int localId = localItem['product_variant_id'];
            int localQty = localItem['quantity'] ?? 1;

            var variantInfo = allVariants.firstWhere((v) => v['id'] == localId, orElse: () => null);

            if (variantInfo != null) {
              double price = double.tryParse(variantInfo['price'].toString()) ?? 0.0;
              final item = CartItem(
                productVariantId: localId,
                productName: variantInfo['name'], 
                productId: variantInfo['product_id'] ?? 0, // Đã đổi thành productId
                imageUrl: variantInfo['image'], 
                price: price,
                quantity: localQty,
              );

              finalCartItems.add(item);
              tempTotalMoney += price * localQty;
            }
          }

          return CartResponse(
            succeeded: true, 
            data: finalCartItems,        
            totalMoney: tempTotalMoney
          );
        }
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin chi tiết cho giỏ hàng Local: $e");
    }

    return CartResponse(succeeded: true, data: [], totalMoney: 0);
  }

  // --- 2. THÊM VÀO GIỎ HÀNG (CHỈ LƯU LOCAL) ---
  static Future<void> addToCart(int productVariantId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> currentList = [];
    String? localCartJson = prefs.getString('local_cart');
    
    if (localCartJson != null && localCartJson.isNotEmpty) {
      try {
        currentList = jsonDecode(localCartJson);
      } catch (e) {
        currentList = [];
      }
    }

    bool exists = false;
    for (var i = 0; i < currentList.length; i++) {
      Map<String, dynamic> item = currentList[i];
      if (item['product_variant_id'] == productVariantId) {
        int currentQty = item['quantity'] ?? 0;
        item['quantity'] = currentQty + quantity; 
        currentList[i] = item;
        exists = true;
        break; 
      }
    }

    if (!exists) {
      currentList.add({
        'product_variant_id': productVariantId,
        'quantity': quantity, 
        'added_at': DateTime.now().toIso8601String(), 
      });
    }

    await prefs.setString('local_cart', jsonEncode(currentList));
  }

  // --- 3. CẬP NHẬT SỐ LƯỢNG (CHỈ LOCAL) ---
  Future<bool> updateCartQuantity(int productVariantId, int newQuantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? localCartJson = prefs.getString('local_cart');
      if (localCartJson == null) return false;

      List<dynamic> currentList = jsonDecode(localCartJson);
      for (var i = 0; i < currentList.length; i++) {
        if (currentList[i]['product_variant_id'] == productVariantId) {
          currentList[i]['quantity'] = newQuantity;
          break;
        }
      }
      await prefs.setString('local_cart', jsonEncode(currentList));
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 4. XÓA SẢN PHẨM KHỎI GIỎ (CHỈ LOCAL) ---
  Future<bool> deleteCartItem(int productVariantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? localCartJson = prefs.getString('local_cart');
      if (localCartJson == null) return false;

      List<dynamic> currentList = jsonDecode(localCartJson);
      currentList.removeWhere((item) => item['product_variant_id'] == productVariantId);
      
      await prefs.setString('local_cart', jsonEncode(currentList));
      return true;
    } catch (e) {
      return false;
    }
  }
}