class Category {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryImg;
  Category({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryImg,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json["categoryId"],
      categoryName: json["categoryName"],
      categoryColor: json["categoryColor"],
      categoryImg: json["categoryImg"],
    );
  }
}
