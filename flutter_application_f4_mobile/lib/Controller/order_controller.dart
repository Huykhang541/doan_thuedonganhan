import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/Order.dart';
import '../Config/baseUrl.dart';

class OrderController { 

  // Lấy danh sách lịch sử mua hàng
  Future<List<Order>> getOrderHistory() async {
    final url = Uri.parse('$baseUrl/orders/order-history');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['orders'] != null) {
          return (data['orders'] as List)
              .map((e) => Order.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Lỗi getOrderHistory: $e");
    }
    return [];
  }

  // Lấy chi tiết đơn hàng
  Future<Order?> getOrderDetail(dynamic orderId) async {
    final url = Uri.parse('$baseUrl/orders/$orderId');
    
    // Lấy token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        // Decode UTF8 để không lỗi font tiếng Việt
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));

        // Kiểm tra cấu trúc trả về
        // API nhóm bạn trả về dạng danh sách các dòng (rows) do join bảng
        if (data['order'] != null && data['order'] is List) {
          List<dynamic> listRaw = data['order'];
          
          if (listRaw.isEmpty) return null;

          // --- Hàm phụ xử lý số (tránh crash khi API trả về String/Double/Int lộn xộn) ---
          int parseNumber(dynamic value) {
            if (value == null) return 0;
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) {
              // Thử parse int, nếu lỗi thì parse double rồi ép về int
              return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
            }
            return 0;
          }

          // --- 1. Lấy thông tin chung của đơn hàng từ dòng đầu tiên ---
          var firstRow = listRaw[0];
          
          // Xử lý địa chỉ: Chỉ thêm dấu phẩy nếu có cả 2 trường
          String fullAddress = firstRow['shipping_address'] ?? '';
          String city = firstRow['city'] ?? '';
          if (fullAddress.isNotEmpty && city.isNotEmpty) {
            fullAddress = "$fullAddress, $city";
          } else if (fullAddress.isEmpty) {
            fullAddress = city; // Nếu không có địa chỉ thì lấy thành phố
          }

          Order finalOrder = Order(
            id: parseNumber(firstRow['id']),
            userId: parseNumber(firstRow['user_id']),
            status: firstRow['status'] ?? "pending",
            createdAt: firstRow['created_at'] ?? "",
            
            // Map các trường tiền tệ
            totalPrice: parseNumber(firstRow['total_money'] ?? firstRow['total_price']), 
            shippingFee: parseNumber(firstRow['shipping_fee']),
            discount: double.tryParse(firstRow['discount'])?? 0.0,
            couponId: parseNumber(firstRow['coupon_id']),
            
            // Map thông tin người nhận
            fullName: firstRow['full_name'],
            phoneNumber: firstRow['phone_number'],
            address: fullAddress,
          );
          print("DEBUG(getOrderDetail-orderController-frontend): ${finalOrder.couponId}");
          // --- 2. Map danh sách sản phẩm (Items) ---
          // Duyệt qua tất cả các dòng trong listRaw để lấy từng sản phẩm
          finalOrder.items = listRaw.map((row) {
            return OrderItem(
              // Ưu tiên lấy product_id, nếu không có thì lấy variant_id
              productId: parseNumber(row['product_id'] ?? row['product_variant_id']),
              
              productName: row['product_name'] ?? "Sản phẩm #${row['product_variant_id']}",
              quantity: parseNumber(row['quantity']),
              price: parseNumber(row['price']),
            );
          }).toList();

          return finalOrder;
        }
      } else {
        print("Lỗi server: ${response.statusCode} - Body: ${response.body}");
      }
    } catch (e) {
      print("Lỗi Exception tại getOrderDetail: $e");
    }
    return null;
  }

  // Lấy danh sách đơn hàng cho admin
  Future<List<Order>> getAllOrdersAdmin() async {
    final url = Uri.parse('$baseUrl/admin/orders');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // CASE 1: Server trả về trực tiếp danh sách [{}, {}]
        if (data is List) {
          return data.map((e) => Order.fromJson(e)).toList();
        } 
        // CASE 2: Server trả về object có key "orders" { "orders": [] }
        else if (data is Map<String, dynamic> && data['orders'] != null) {
          return (data['orders'] as List)
              .map((e) => Order.fromJson(e))
              .toList();
        }
      } else {
        print("Lỗi Admin Order: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception Admin Order: $e");
    }
    return [];
  }

  // Admin cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(dynamic orderId, String newStatus) async {
    final url = Uri.parse('$baseUrl/admin/approve-order/$orderId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "curStatus": newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi server trả về: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi Exception: $e");
      return false;
    }
  }

  Future<bool> cancelOrder(int order_id) async {
    try{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');
      final respone = await http.delete(
        Uri.parse('$baseUrl/orders/cancel/$order_id'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        }
      );

      if(respone.statusCode == 200){
        final Map<String, dynamic> data = jsonDecode(respone.body);

        return data['succeeded'];
      }
      else{
        return false;
      }
    }
    catch(e){
      print("Lỗi hủy đơn hàng: $e");
    }
    return false;
  }
}