import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/cartModel.dart';
import '../Config/baseUrl.dart';

class CartController {

  // --- 1. LẤY GIỎ HÀNG (ƯU TIÊN DỮ LIỆU ĐÃ LƯU CHUẨN TỪ TRANG CHI TIẾT) ---
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

    List<dynamic> allVariants = [];
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/products/product-variants/get-all'),
          headers: {"ngrok-skip-browser-warning": "true"}  
      );
      if (response.statusCode == 200) {
        final serverData = jsonDecode(response.body);
        if (serverData['succeeded'] == true) {
          allVariants = serverData['product_variants'] ?? [];
        }
      }
    } catch (e) {
      print("Lỗi lấy danh sách biến thể dự phòng: $e");
    }

    List<CartItem> finalCartItems = [];
    double tempTotalMoney = 0.0;

    for (var localItem in localList) {
      int localId = localItem['product_variant_id'] ?? 0;
      int localQty = localItem['quantity'] ?? 1;
      int localRentalDays = localItem['rental_days'] ?? 1;
      double localDeposit = double.tryParse(localItem['deposit']?.toString() ?? '0') ?? 0.0;

      // Tìm thông tin từ server nếu có
      var variantInfo = allVariants.firstWhere((v) => v['id'] == localId, orElse: () => null);

      // [FIX ẢNH BIẾN THỂ]: Ưu tiên lấy ảnh, tên, giá đã lưu trực tiếp từ lúc khách chọn màu sắc
      String itemImg = localItem['image_url'] ?? (variantInfo != null ? variantInfo['image'] : '') ?? '';
      String itemName = localItem['product_name'] ?? (variantInfo != null ? variantInfo['name'] : 'Sản phẩm');
      int itemProdId = localItem['product_id'] ?? (variantInfo != null ? (variantInfo['product_id'] ?? 0) : 0);
      double itemPrice = double.tryParse(localItem['price']?.toString() ?? '') ?? 
                         (variantInfo != null ? (double.tryParse(variantInfo['price'].toString()) ?? 0.0) : 0.0);

      final item = CartItem(
        productVariantId: localId,
        productName: itemName, 
        productId: itemProdId, 
        imageUrl: itemImg, 
        price: itemPrice,
        quantity: localQty,
        rentalDays: localRentalDays,
        deposit: localDeposit,
      );

      finalCartItems.add(item);
      tempTotalMoney += ((itemPrice * localRentalDays) + localDeposit) * localQty;
    }

    return CartResponse(
      succeeded: true, 
      data: finalCartItems,        
      totalMoney: tempTotalMoney
    );
  }

  // --- 2. THÊM VÀO GIỎ HÀNG (LƯU KÈM ẢNH, TÊN, GIÁ CỦA BIẾN THỂ ĐÃ CHỌN) ---
  static Future<void> addToCart(
    int productVariantId, 
    int quantity, 
    int rentalDays, 
    double deposit, {
    int? productId,
    String? productName,
    double? price,
    String? imageUrl,
  }) async {
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
        item['rental_days'] = rentalDays; 
        item['deposit'] = deposit;
        if (imageUrl != null && imageUrl.isNotEmpty) item['image_url'] = imageUrl;
        if (productName != null && productName.isNotEmpty) item['product_name'] = productName;
        if (price != null) item['price'] = price;
        if (productId != null) item['product_id'] = productId;
        
        currentList[i] = item;
        exists = true;
        break; 
      }
    }

    if (!exists) {
      currentList.add({
        'product_variant_id': productVariantId,
        'product_id': productId ?? 0,
        'product_name': productName ?? 'Sản phẩm',
        'price': price ?? 0.0,
        'image_url': imageUrl ?? '',
        'quantity': quantity, 
        'rental_days': rentalDays,
        'deposit': deposit,
        'added_at': DateTime.now().toIso8601String(), 
      });
    }

    await prefs.setString('local_cart', jsonEncode(currentList));
  }

  // --- 3. CẬP NHẬT SỐ LƯỢNG ---
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

  // --- 4. XÓA SẢN PHẨM KHỎI GIỎ ---
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