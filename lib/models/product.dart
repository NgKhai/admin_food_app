import '../models/category.dart';

class Product {
  final String productId;
  final String productName;
  final String productImg;
  final int productPreparationTime;
  final int productCalo;
  final num productPrice;
  final String productDescription;
  final bool productStatus;
  final String categoryId;
  late final Category? category; // Added category field
  List<ProductSize> sizes; // Make it mutable since we update later

  Product({
    required this.productId,
    required this.productName,
    required this.productImg,
    required this.productPreparationTime,
    required this.productCalo,
    required this.productPrice,
    required this.productDescription,
    required this.productStatus,
    required this.categoryId,
    this.category,
    this.sizes = const [], // Default empty list
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json["productId"] ?? "",
      productName: json["productName"] ?? "Unknown",
      productImg: json["productImg"] ?? "",
      productPreparationTime: json["productPreparationTime"] ?? 0,
      productCalo: json["productCalo"] ?? 0,
      productPrice: json["productPrice"] ?? 0,
      productDescription: json["productDescription"] ?? "",
      productStatus: json["productStatus"] ?? false,
      categoryId: json["categoryId"] ?? "",
      sizes: (json["sizes"] as List<dynamic>?)
          ?.map((e) => ProductSize.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "productName": productName,
      "productImg": productImg,
      "productPreparationTime": productPreparationTime,
      "productCalo": productCalo,
      "productPrice": productPrice,
      "productDescription": productDescription,
      "productStatus": productStatus,
      "categoryId": categoryId,
      // "category": category?.toJson(), // Ensure category is serialized
      "sizes": sizes.map((size) => size.toJson()).toList(),
    };
  }
}

class ProductSize {
  final String sizeId;
  final String sizeName;
  final num extraPrice;

  ProductSize({
    required this.sizeId,
    required this.sizeName,
    required this.extraPrice,
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      sizeId: json["sizeId"],
      sizeName: json["sizeName"],
      extraPrice: json["extraPrice"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "sizeId": sizeId,
      "sizeName": sizeName,
      "extraPrice": extraPrice,
    };
  }
}
