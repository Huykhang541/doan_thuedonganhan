class BrandsModel{
  final int id;
  final String name;
  final String image_url;

  BrandsModel({
    required this.id,
    required this.image_url,
    required this.name
  });

  factory BrandsModel.fromJson(Map<String, dynamic> json) {
    // Tìm ID từ nhiều trường hợp tên key khác nhau
    var rawId = json['MaDanhMuc'] ?? json['madanhmuc'] ?? json['ma_danh_muc'] ?? json['id'] ?? json['categoryId'];
    
    // Tìm Tên danh mục từ nhiều trường hợp
    var rawName = json['TenDanhMuc'] ?? json['tendanhmuc'] ?? json['ten_danh_muc'] ?? json['name'] ?? 'Danh mục';
    
    // Tìm Hình ảnh từ nhiều trường hợp
    var rawImage = json['HinhAnh'] ?? json['hinhanh'] ?? json['hinh_anh'] ?? json['image'] ?? json['image_url'] ?? '';

    return BrandsModel(
      id: rawId != null ? int.tryParse(rawId.toString()) ?? 0 : 0,
      name: rawName.toString(),
      image_url: rawImage.toString(),
    );
  }
}