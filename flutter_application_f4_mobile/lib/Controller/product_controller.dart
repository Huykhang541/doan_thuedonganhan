import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/product_model.dart';
import '../Config/baseUrl.dart';
import '../Model/review_model.dart';

class ProductController {
  
  // ĐÂY LÀ BIẾN BỊ THIẾU GÂY LỖI
  static final Map<String, String> _headers = {
    "ngrok-skip-browser-warning": "true",
    "Accept": "application/json",
    "Content-Type": "application/json",
  };

  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products"), headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data['succeeded'] == true && data['products'] != null) {
          final List<dynamic> productList = data['products'];
          return productList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) { print("Error fetchProducts: $e"); }
    return [];
  }

  static Future<Product?> getProductDetail(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/$id"), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['succeeded'] == true && data['product'] != null) {
          return Product.fromJson(data['product'] as Map<String, dynamic>);
        }
      }
    } catch (e) { print("Error getProductDetail: $e"); }
    return null;
  }

  static Future<Product?> fetchProductById(int id) async { return getProductDetail(id); }

  static Future<List<Product>> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/search?q=$keyword"), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['succeeded'] == true && data['products'] != null) {
          final List<dynamic> list = data['products'];
          return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) { print("Error searchProducts: $e"); }
    return [];
  }

  // HÀM LẤY ĐÁNH GIÁ (ĐÃ ĐƯỢC CHUẨN HÓA)
  static Future<ReviewData?> getReviews(int productId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reviews/$productId"), headers: _headers);
      if (response.statusCode == 200) {
        final jsonMap = json.decode(utf8.decode(response.bodyBytes));
        final res = ReviewResponse.fromJson(jsonMap as Map<String, dynamic>);
        if (res.succeeded && res.data != null) return res.data; 
      }
    } catch (e) { print("Error getReviews: $e"); }
    return null;
  }

  // HÀM GỬI ĐÁNH GIÁ (ĐÃ ĐƯỢC CHUẨN HÓA)
  static Future<bool> postReview(int productId, String content, double rating) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');
      if (token == null || token.isEmpty) return false;

      final url = Uri.parse('$baseUrl/reviews/add');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId, 'rating': rating.toInt(), 'comment': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['succeeded'] == true || data['success'] == true || data.containsKey('message') || data.containsKey('insertId'); 
        }
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  static Future<List<ProductVariant>> getAllProductVariants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/product-variants/get-all'), headers: _headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['succeeded'] == true) {
          List<dynamic> variantList = responseData['product_variants'];
          return variantList.map((item) => ProductVariant.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) { print("Error getAllProductVariants: $e"); }
    return [];
  }

  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/search?category_id=$categoryId"), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['succeeded'] == true && data['products'] != null) {
          final List<dynamic> list = data['products'];
          return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(); 
        }
      }
    } catch (e) { print("Error getProductsByCategory: $e"); }
    return [];
  }
}