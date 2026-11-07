class FavoriteModel {
  final int id;
  final int productID;
  final String name;
  final double price;
  final String image;

  FavoriteModel({
    required this.id,
    required this.productID,
    required this.name,
    required this.price,
    required this.image
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] ?? 0,
      productID: json['productID'] ?? json['product_id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'] ?? ''
    );
  }
}

class FavoriteRespone {
  final bool succeeded;
  final String? message;
  final List<FavoriteModel>? favorites;

  FavoriteRespone({
    required this.succeeded,
    this.favorites,
    this.message
  });

  factory FavoriteRespone.fromJson(Map<String, dynamic> json){
    return FavoriteRespone(
      succeeded: json['succeeded'],
      message: json['message'],
      favorites: json['favorites'] != null 
          ? (json['favorites'] as List).map((i) => FavoriteModel.fromJson(i)).toList()
          : []
    );
  }
}