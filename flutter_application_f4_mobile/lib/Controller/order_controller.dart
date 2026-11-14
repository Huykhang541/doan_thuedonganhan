import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/Order.dart';
import '../Config/baseUrl.dart';

class OrderController { 

  Future<List<Order>> getOrderHistory() async {
    final url = Uri.parse('$baseUrl/orders/my-orders'); 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['orders'] != null) {
          return (data['orders'] as List).map((e) => Order.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print("Lỗi getOrderHistory: $e");
    }
    return [];
  }

  Future<Order?> getOrderDetail(dynamic orderId) async {
    // FIX: Sửa URL đồng bộ với backend "/orders/detail/:orderID"
    final url = Uri.parse('$baseUrl/orders/detail/$orderId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return null; // Tránh lỗi 401

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
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data is Map<String, dynamic> && data['succeeded'] == false) {
           print("Server báo lỗi: ${data['message']}");
           return null;
        }

        Map<String, dynamic>? orderRaw;
        List<dynamic> itemsRaw = [];

        if (data is Map<String, dynamic>) {
          if (data.containsKey('order')) {
            if (data['order'] is List && data['order'].isNotEmpty) {
              orderRaw = Map<String, dynamic>.from(data['order'][0]);
              itemsRaw = data['order'];
            } else if (data['order'] is Map) {
              orderRaw = Map<String, dynamic>.from(data['order']);
              if (orderRaw['items'] != null) {
                itemsRaw = orderRaw['items'];
              }
            }
          } else {
            orderRaw = Map<String, dynamic>.from(data);
            if (data['items'] != null) {
              itemsRaw = data['items'];
            }
          }
        } else if (data is List && data.isNotEmpty) {
           orderRaw = Map<String, dynamic>.from(data[0]);
           itemsRaw = data;
        }

        if (orderRaw != null) {
          orderRaw['items'] = itemsRaw;
          return Order.fromJson(orderRaw);
        }
      } else {
        print("Lỗi HTTP tại getOrderDetail: ${response.statusCode} - Body: ${response.body}");
      }
    } catch (e, stacktrace) {
      print("Lỗi Exception tại getOrderDetail: $e");
      print(stacktrace);
    }
    return null;
  }

  Future<List<Order>> getAllOrdersAdmin() async {
    // [FIX]: Thêm /orders/ vào trước /admin 
    final url = Uri.parse('$baseUrl/orders/admin/orders');
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

        if (data is List) {
          return data.map((e) => Order.fromJson(e)).toList();
        } 
        else if (data is Map<String, dynamic> && data['orders'] != null) {
          return (data['orders'] as List).map((e) => Order.fromJson(e)).toList();
        }
      } else {
        print("Lỗi Admin Order: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception Admin Order: $e");
    }
    return [];
  }

  Future<bool> updateOrderStatus(dynamic orderId, String newStatus) async {
   final url = Uri.parse('$baseUrl/orders/admin/approve-order/$orderId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      // FIX: Chuyển thành http.put để đồng bộ với route PUT của backend 
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "status": newStatus, // Đổi "curStatus" thành "status" cho chuẩn với backend
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

      if (token == null) return false;
      
      final response = await http.put(
        Uri.parse('$baseUrl/orders/cancel/$order_id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if(response.statusCode == 200){
        final Map<String, dynamic> data = jsonDecode(response.body);
        // FIX: Đảm bảo Type Safety tuyệt đối cho bool
        return data['succeeded'] == true; 
      }
      return false;
    }
    catch(e){
      print("Lỗi hủy đơn hàng: $e");
      return false;
    }
  }
}