import '../Config/baseUrl.dart'; // Import file chứa đường dẫn gốc của server (API)

// ==========================================
// 1. LỚP ĐẠI DIỆN CHO SẢN PHẨM CHÍNH
// ==========================================
class Product {
  // Khai báo các thuộc tính (cột dữ liệu) của một sản phẩm
  final int id;                 // Mã sản phẩm
  final int brandId;            // Mã danh mục / thương hiệu
  final String name;            // Tên sản phẩm
  final String description;     // Mô tả chi tiết
  final double price;           // Giá thuê
  final double? deposit;        // Tiền cọc (có thể null nếu không yêu cầu cọc)
  final String? brandName;      // Tên danh mục (có thể null)
  final String imageUrl;        // Đường dẫn ảnh chính của sản phẩm
  final int soldCount;          // Số lượng đã cho thuê/bán
  final String createdAt;       // Ngày tạo sản phẩm
  final double averageRating;   // Số sao đánh giá trung bình
  final int reviewCount;        // Tổng số lượt đánh giá
  final String status;          // Trạng thái (Còn hàng/Hết hàng) - Thêm sẵn cho bạn

  final List<ProductVariant>? variants; // Danh sách các biến thể (ví dụ: các màu, size) của sản phẩm

  // Constructor (Hàm khởi tạo) yêu cầu truyền dữ liệu vào khi tạo đối tượng
  Product({
    required this.id,
    required this.brandId,
    required this.name,
    required this.description,
    required this.price,
    this.deposit,
    this.brandName,
    required this.imageUrl,
    required this.soldCount,
    required this.createdAt,
    required this.averageRating,
    required this.reviewCount,
    this.variants,
    this.status = 'Unknown', // Giá trị mặc định nếu không truyền
  });

  // Hàm chuyển đổi cục dữ liệu JSON (từ API trả về) thành 1 đối tượng Product trong App
  factory Product.fromJson(Map<String, dynamic> json) {
    
    // --- HÀM HỖ TRỢ XỬ LÝ ĐƯỜNG DẪN ẢNH ---
    // Kiểm tra và nối URL gốc (baseUrl) với tên file ảnh để ra link ảnh hoàn chỉnh
    String getFullUrl(String? path) {
      if (path == null || path.isEmpty || path == "null") return ""; // Nếu không có ảnh thì trả về chuỗi rỗng
      if (path.startsWith("http")) return path; // Nếu ảnh đã là link web đầy đủ thì giữ nguyên
      
      // Lấy domain gốc, bỏ đuôi '/api' hoặc dấu '/' ở cuối đi cho chuẩn form
      String rootUrl = baseUrl.endsWith('/api') ? baseUrl.replaceAll('/api', '') : baseUrl;
      String cleanRoot = rootUrl.endsWith('/') ? rootUrl.substring(0, rootUrl.length - 1) : rootUrl;
      // Đảm bảo tên file ảnh luôn bắt đầu bằng dấu '/'
      String cleanPath = path.startsWith('/') ? path : '/$path';
      
      return "$cleanRoot$cleanPath"; // Ghép domain và file ảnh lại
    }

    // --- XỬ LÝ DANH SÁCH BIẾN THỂ ---
    List<ProductVariant>? variantsList;
    if (json['variants'] != null) {
      var list = json['variants'] as List; // Ép mảng json thành List
      // Chạy vòng lặp map để chuyển từng cục json con thành đối tượng ProductVariant
      variantsList = list.map((i) => ProductVariant.fromJson(i)).toList();
    }

    // --- XỬ LÝ LỖI LẤY NHẦM ẢNH (Logic cũ của bạn) ---
    String parsedImage = "";
    if (json.containsKey('DuongDanAnhHome')) {
      // Ưu tiên lấy ảnh chính để không bị nhảy sang ảnh của biến thể đầu tiên
      parsedImage = json['DuongDanAnhHome'] != null ? json['DuongDanAnhHome'].toString() : "";
    } else {
      // Fallback: Tìm các key tên khác xem API có trả về không
      parsedImage = json['image_url'] ?? json['imageUrl'] ?? json['image'] ?? json['DuongDanAnh'] ?? "";
    }

    // --- XỬ LÝ LỖI GIÁ (Logic cũ của bạn) ---
    double parsedPrice = 0.0;
    if (json['GiaThueTheoNgay'] != null) {
      // Ép thành chữ rồi mới ép qua số thực (tránh lỗi nếu API lỡ trả về kiểu chữ hoặc số nguyên)
      parsedPrice = double.tryParse(json['GiaThueTheoNgay'].toString()) ?? 0.0;
    } else if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    // Trả về đối tượng Product hoàn chỉnh sau khi đã nhặt và gán hết dữ liệu
    return Product(
      // Dùng .tryParse và ?? để phòng hờ API đổi tên cột (id hoặc MaSanPham) và chống crash nếu dữ liệu bị null
      id: int.tryParse((json['id'] ?? json['MaSanPham'] ?? 0).toString()) ?? 0,
      brandId: int.tryParse((json['brand_id'] ?? json['MaDanhMuc'] ?? 0).toString()) ?? 0,
      name: json['name'] ?? json['TenSanPham'] ?? '',
      description: json['description'] ?? json['MoTa'] ?? '',
      price: parsedPrice,
      deposit: json['deposit'] != null ? double.tryParse(json['deposit'].toString()) : null,
      brandName: json['brand_name'],
      imageUrl: getFullUrl(parsedImage), // Gọi hàm getFullUrl ở trên để nối link ảnh
      soldCount: int.tryParse((json['sold_count'] ?? 0).toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      
      // (ĐÃ SỬA) Đổi .parse thành .tryParse để an toàn tuyệt đối, không bao giờ bị văng app
      averageRating: double.tryParse(json['averageRating']?.toString() ?? '') ?? 0.0,
      reviewCount: int.tryParse(json['reviewCount']?.toString() ?? '') ?? 0,
      status: json['TrangThai'] ?? json['status'] ?? 'Unknown', // Đọc cột trạng thái
      
      variants: variantsList, // Gắn danh sách biến thể vào
    );
  }
}

// ==========================================
// 2. LỚP ĐẠI DIỆN CHO BIẾN THỂ SẢN PHẨM (Màu sắc, kích cỡ...)
// ==========================================
class ProductVariant {
  // Khai báo các thuộc tính của biến thể
  final int id;
  final int? brandId;
  final String? name;
  final String? description;
  final int? productId; // ID của sản phẩm gốc chứa biến thể này
  final String? color;  // Màu sắc
  final double? price;
  final double? deposit;
  final int? stockQuantity; // Số lượng tồn kho của biến thể này
  final String? imageUrl;   // Ảnh riêng của biến thể (nếu lều xanh thì ảnh màu xanh)

  // Constructor
  ProductVariant({
    required this.id,
    this.brandId,
    this.name,
    this.description,
    this.productId,
    this.color,
    this.price,
    this.deposit,
    this.stockQuantity,
    this.imageUrl,
  });

  // Hàm chuyển JSON thành đối tượng ProductVariant
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    // Tìm mã danh mục dựa trên nhiều tên key khác nhau mà BE có thể trả về
    var rawBrandId = json['MaDanhMuc'] ?? json['madanhmuc'] ?? json['ma_danh_muc'] ?? json['brandId'] ?? json['categoryId'];

    // Lại khai báo 1 hàm xử lý ảnh y hệt như bên trên (để đảm bảo tính độc lập cho class này)
    String getFullUrl(String? path) {
      if (path == null || path.isEmpty || path == "null") return "";
      if (path.startsWith("http")) return path;
      String rootUrl = baseUrl.endsWith('/api') ? baseUrl.replaceAll('/api', '') : baseUrl;
      String cleanRoot = rootUrl.endsWith('/') ? rootUrl.substring(0, rootUrl.length - 1) : rootUrl;
      String cleanPath = path.startsWith('/') ? path : '/$path';
      return "$cleanRoot$cleanPath";
    }

    return ProductVariant(
      // Parsing các trường tương tự như Product
      id: int.tryParse((json['id'] ?? json['MaBienThe'] ?? 0).toString()) ?? 0,
      name: json['name'] ?? json['TenSanPham'],
      description: json['description'] ?? json['MoTa'],
      productId: json['product_id'] != null ? int.tryParse(json['product_id'].toString()) : null,
      color: json['color'] ?? json['MauSac'],
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : 0.0,
      deposit: json['deposit'] != null ? double.tryParse(json['deposit'].toString()) : 0.0,
      stockQuantity: json['stock_quantity'] != null ? int.tryParse(json['stock_quantity'].toString()) : 0,
      imageUrl: getFullUrl(json['image'] ?? json['imageUrl'] ?? json['image_url'] ?? json['DuongDanAnh']),
      brandId: rawBrandId != null ? int.tryParse(rawBrandId.toString()) ?? 0 : 0,
    );
  }
}