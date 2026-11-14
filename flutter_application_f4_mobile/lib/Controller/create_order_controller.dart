import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/create_order_model.dart';
import '../Model/cartModel.dart';
import '../Config/baseUrl.dart';

class CreateOrderController {
  Future<int> createOrder({
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String couponCode,
    required String note,
    required double totalPrice,
    required bool isBuyNow,
    required String paymentMethod,
    required String ngayThue, 
    required String ngayTra,  
    required List<CartItem> cartItems,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');

      if (token == null) return 0;

      List<OrderDetailItem> details = cartItems.map((item) {
        double price = item.price ?? 0;
        int qty = item.quantity ?? 1;
        
        // [FIX]: Lấy thêm số ngày thuê và tiền cọc từ giỏ hàng
        int rentalDays = item.rentalDays ?? 1;
        double deposit = item.deposit ?? 0;

        return OrderDetailItem(
          productId: item.productId ?? 0, 
          productVariantId: item.productVariantId,
          price: price,
          quantity: qty,
          // [FIX]: Tính toán tiền của từng món chuẩn xác giống như trên giao diện UI
          totalMoney: ((price * rentalDays) + deposit) * qty,
        );
      }).toList();

      final requestBody = CreateOrderRequest(
        fullName: fullName,
        phoneNumber: phone,
        address: address,
        city: city,
        couponCode: couponCode,
        note: note,
        totalMoney: totalPrice,
        paymentMethod: paymentMethod,
        is_buy_now: isBuyNow,
        ngayThue: ngayThue,
        ngayTra: ngayTra,
        orderDetails: details,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/orders'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CreateOrderResponse.fromJson(jsonDecode(response.body)).order_id;
      } else {
        throw Exception("${jsonDecode(response.body)['message']}");
      }
    } catch (e) {
      debugPrint("Lỗi tạo đơn: $e");
    }
    return 0;
  }
}