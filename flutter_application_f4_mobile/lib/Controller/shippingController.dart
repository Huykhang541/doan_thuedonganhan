import 'dart:convert';
import 'package:flutter_application_f4_mobile/Model/shippingModel.dart';
import 'package:http/http.dart' as http;
import '../Config/baseUrl.dart';

class Shippingcontroller {
  static Future<String?> getShippingFee(String city) async{
    try{
      final respone = await http.get(
        Uri.parse('$baseUrl/shipping/?city=$city'),
        headers: {
          'ngrok-skip-browser-warning': 'true'
        }
      );

      if(respone.statusCode == 200){
        final data = jsonDecode(respone.body);
        return ShippingModel.fromJson(data).shippingFee;
      }
      else{
        final data = jsonDecode(respone.body);
        return ShippingModel.fromJson(data).message;
      }
    }
    catch(e){
      print("Lỗi lấy phí ship: $e");
    }
  }
}