import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/couponModel.dart'; // Import model bạn đã tạo ở bước trước
import '../Config/baseUrl.dart';

class CouponController {
  // Hàm lấy danh sách Coupon từ API
  static Future<List<CouponModel>> getCoupons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coupons'),
        headers: {
          'accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        
        // Kiểm tra cấu trúc trả về dựa trên JSON mẫu của bạn
        if (jsonData['succeeded'] == true) {
          List<dynamic> listData = jsonData['coupons'];
          return listData.map((e) => CouponModel.fromJson(e)).toList();
        } else {
          throw Exception("API trả về lỗi logic: ${jsonData['message']}");
        }
      } else {
        throw Exception("Lỗi Server: ${response.statusCode}");
      }
    } catch (e) {
      // In lỗi ra console để debug
      print("Error fetching coupons: $e");
      return []; // Trả về danh sách rỗng nếu lỗi để app không bị crash
    }
  }

  static Future<CouponModel?> getCoupon(int? couponId) async {
    try{
      final respone = await http.get(
        Uri.parse('$baseUrl/coupons/${couponId ?? 0}'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        }
      );

      if(respone.statusCode == 200){
        final Map<String, dynamic> data = jsonDecode(respone.body);

        if(data['succeeded']){
          print("getCoupon: ${data['message']}, ${data['succeeded']}, ${data['scoupon']}");
          return CouponModel.fromJson(data['coupon']);
        }
        else{
          print("Lỗi(getCoupon): ${data['message']}");
          throw Exception("Lỗi(getCoupon): ${data['message']}");
        }
      }
    }catch(e){
      print("Lỗi(getCoupon): $e");
      throw Exception("$e");
    }
  }

  // Hàm tính toán số tiền được giảm dựa trên coupon và tổng đơn hàng
  double calculateDiscount(CouponModel coupon, double currentOrderTotal) {
    // 1. Kiểm tra đơn tối thiểu
    if (currentOrderTotal < coupon.minOrderValue) return 0;

    double amount = 0;

    // 2. Tính toán dựa trên loại giảm giá
    if (coupon.discountType == 'fixed') {
      amount = coupon.discountValue;
    } else if (coupon.discountType == 'percent') {
      amount = currentOrderTotal * (coupon.discountValue / 100);
    }

    // 3. Kiểm tra giảm tối đa (nếu có)
    if (coupon.maxDiscountAmount != null && amount > coupon.maxDiscountAmount!) {
      amount = coupon.maxDiscountAmount!;
    }

    return amount;
  }
}