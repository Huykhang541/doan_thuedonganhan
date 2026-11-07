import 'dart:developer' as dev;
import 'dart:convert';

void logPrettyJsonString(String jsonString) {
  try {
    // BƯỚC 1: Biến chuỗi String hỗn độn thành Object (Map hoặc List)
    dynamic jsonObject = jsonDecode(jsonString);

    // BƯỚC 2: Biến Object đó trở lại thành String nhưng có định dạng đẹp (thụt lề 2 space)
    var encoder = const JsonEncoder.withIndent("  ");
    String prettyString = encoder.convert(jsonObject);

    // BƯỚC 3: Dùng log thay vì print để tránh bị cắt bớt nếu nội dung quá dài
    dev.log(prettyString, name: 'JSON PRETTY'); 
    
  } catch (e) {
    // Nếu chuỗi không đúng chuẩn JSON, in báo lỗi và in chuỗi gốc
    print("Lỗi format JSON: $e");
    print(jsonString);
  }
}