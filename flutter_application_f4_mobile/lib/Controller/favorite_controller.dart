import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/favorite_model.dart';
import '../Config/baseUrl.dart';

class FavoriteController {
  static Map<String, String> getHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>?> fecthFavorite() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token') ?? '';
    
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: getHeaders(token),
    );

    // Decode JSON thành Map
    final data = jsonDecode(utf8.decode(response.bodyBytes)); // Dùng utf8 để không lỗi font tiếng Việt

    if (response.statusCode == 200) {
      // SỬA Ở ĐÂY: Gọi hàm fromJson để chuyển Map -> Object
      final favoriteResponeObj = FavoriteRespone.fromJson(data);
      
      return {
        'succeeded': true,
        'favoriteRespone': favoriteResponeObj // Trả về Object đã parse
      };
    } else {
      return {
        'succeeded': false,
        'favoriteRespone': data['message'] ?? "Lỗi không xác định"
      };
    }
  } catch (e) {
    print("Lỗi fetchFavorite: $e");
    return null;
  }
}

  static Future<bool> addFavorite(int productId) async {
    print("DEBUG(favorite ADD PRODUCT_VARIANT_ID): $productId");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/add/$productId'),
        headers: getHeaders(token),
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFavorite(int productId) async {
    print("DEBUG(favorite REMOVE PRODUCT_VARIANT_ID): $productId");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token') ?? '';
      
      // Sửa lại URL cho khớp với lệnh ADD (thêm /products)
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/remove/$productId'),
        headers: getHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkIsFavorite(int productId) async {
    try {
      Map<String, dynamic>? list = await fecthFavorite();
      if(list != null && list['succeeded'] != false){
        final FavoriteRespone respone = list['favoriteRespone'];
        print("DEBUG: ${respone.succeeded}");
        final List<FavoriteModel>? favorites = respone.favorites;
        if(favorites != null && favorites.isNotEmpty){
          return favorites.any((element) => element.productID == productId);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}