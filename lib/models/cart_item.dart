import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String cartItemId;
  final String productId;
  final String sizeId;
  final num unitPrice;
  final int quantity;
  final num totalPrice;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.sizeId,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Chuyển đổi từ JSON (Firestore Document) sang CartItem
  factory CartItem.fromJson(String id, Map<String, dynamic> json) {
    return CartItem(
      cartItemId: id,
      productId: json['productId'] ?? '',
      sizeId: json['sizeId'] ?? '',
      unitPrice: json['unitPrice'] ?? 0,
      quantity: json['quantity'] ?? 1,
      totalPrice: json['totalPrice'] ?? 0,
      userId: json['userId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Chuyển đổi CartItem sang JSON để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sizeId': sizeId,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
