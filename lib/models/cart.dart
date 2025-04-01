import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class Cart {
  final String cartId;
  final List<CartItem> cartItem;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.cartId,
    required this.cartItem,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(String id, Map<String, dynamic> json) {
    return Cart(
      cartId: id, // ID của Cart lấy từ Firestore document ID
      cartItem: (json['cartItem'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(
                  item['cartItemId'], item as Map<String, dynamic>))
              .toList() ??
          [],
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Chuyển đổi CartItem sang JSON để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'cartItem': cartItem.map((item) => item.toJson()).toList(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
