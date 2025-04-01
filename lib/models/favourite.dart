class Favourite {
  final String favouriteId;
  final String productId;
  final String userId;

  Favourite({
    required this.favouriteId,
    required this.productId,
    required this.userId,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) {
    return Favourite(
      favouriteId: json["favouriteId"] ?? "",
      productId: json["productId"] ?? "", // Fixed from productName to productId
      userId: json["userId"] ?? "", // Fixed from productImg to userId
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "favouriteId": favouriteId,
      "productId": productId,
      "userId": userId,
    };
  }
}
