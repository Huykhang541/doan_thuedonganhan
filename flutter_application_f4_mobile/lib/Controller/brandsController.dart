import 'dart:convert';
import '../Model/brandsModel.dart';
import 'package:http/http.dart' as http;
import '../Config/baseUrl.dart';
import '../debugConfig/fromJson.dart';

class BrandsController{
  static Future<List<BrandsModel>> getAllBrands()async{
    try{
      final respone = await http.get(
        Uri.parse("$baseUrl/categories"),
        headers: {
          "ngrok-skip-browser-warning": "true",
        }
      );
      logPrettyJsonString(respone.body);
      if(respone.statusCode == 200){
        var decoded = jsonDecode(respone.body);
        List<dynamic> brandsData = [];

        // Xử lý linh hoạt cấu trúc JSON trả về
        if (decoded is List) {
          brandsData = decoded;
        } else if (decoded is Map && decoded['categories'] != null) {
          brandsData = decoded['categories'];
        } else if (decoded is Map && decoded['data'] != null) {
          brandsData = decoded['data'];
        }
        return brandsData.map((brand) => BrandsModel.fromJson(brand)).toList();
      }
      return [];
    }
    catch(e){
      print("DEBUG (getAllBrands): $e");
      throw Exception("Lỗi server (brands): $e");
    }
  }
}