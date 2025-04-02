import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';

class OrderProduct {
  final String orderId;
  final String userId;
  final String? nameCustomer;
  final String? orderCouponId;
  final String? shippingCouponId;
  final String pickUpAddressId;
  final String? deliveryAddressName;
  final double? deliveryAddressLatitude;
  final double? deliveryAddressLongitude;
  final List<CartItem> listCartItem;
  final double deliveryFee;
  final double? orderDiscount;
  final double? deliveryDiscount;
  final bool rewardDiscount;
  final double rewardedPoint;
  final String paymentMethod;
  final double totalPrice;
  final String? note;
  final String status;
  final int? ratedBar; // rated from 1 to 5
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderProduct(
    this.orderId,
    this.userId,
    this.nameCustomer,
    this.orderCouponId,
    this.shippingCouponId,
    this.pickUpAddressId,
    this.deliveryAddressName,
    this.deliveryAddressLatitude,
    this.deliveryAddressLongitude,
    this.listCartItem,
    this.deliveryFee,
    this.orderDiscount,
    this.deliveryDiscount,
    this.rewardDiscount,
    this.rewardedPoint,
    this.paymentMethod,
    this.totalPrice,
    this.note,
    this.status,
    this.ratedBar,
    this.feedback,
    this.createdAt,
    this.updatedAt,
  );

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      json['orderId'] ?? '',
      json['userId'] ?? '',
      json['nameCustomer'] ?? '',
      json['orderCouponId'],
      json['shippingCouponId'],
      json['pickUpAddressId'] ?? '',
      json['deliveryAddressName'],
      (json['deliveryAddressLatitude'] as num?)?.toDouble(),
      (json['deliveryAddressLongitude'] as num?)?.toDouble(),
      (json['listCartItem'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson('cart id', item))
          .toList() ?? [],
      (json['deliveryFee'] as num).toDouble(),
      (json['orderDiscount'] as num?)?.toDouble(),
      (json['deliveryDiscount'] as num?)?.toDouble(),
      json['rewardDiscount'] ?? false,
      (json['rewardedPoint'] as num).toDouble(),
      json['paymentMethod'] ?? '',
      (json['totalPrice'] as num).toDouble(),
      json['note'],
      json['status'] ?? '',
      json['ratedBar'],
      json['feedback'],
      (json['createdAt'] as Timestamp).toDate(),
      (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'nameCustomer': nameCustomer,
      'orderCouponId': orderCouponId,
      'shippingCouponId': shippingCouponId,
      'pickUpAddressId': pickUpAddressId, // Convert Address to JSON
      'deliveryAddressName': deliveryAddressName,
      'deliveryAddressLatitude': deliveryAddressLatitude,
      'deliveryAddressLongitude': deliveryAddressLongitude,
      'listCartItem': listCartItem.map((item) => item.toJson()).toList(), // Convert List<CartItem> to JSON
      'deliveryFee': deliveryFee,
      'orderDiscount': orderDiscount,
      'deliveryDiscount': deliveryDiscount,
      'rewardDiscount': rewardDiscount,
      'rewardedPoint': rewardedPoint,
      'paymentMethod': paymentMethod,
      'totalPrice': totalPrice,
      'note': note,
      'status': status,
      'ratedBar': ratedBar,
      'feedback': feedback,
      'createdAt': Timestamp.fromDate(createdAt), // Convert DateTime to Firestore Timestamp
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
