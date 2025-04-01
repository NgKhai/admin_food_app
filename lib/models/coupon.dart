import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String couponId;
  final String couponName;
  final String couponImageUrl;
  final double discountValue;
  final bool isPercentage;
  final DateTime expiredDate;
  final double minPurchaseAmount;
  final double? maxDiscountValue;
  final CouponType type;

  Coupon({
    required this.couponId,
    required this.couponName,
    required this.couponImageUrl,
    required this.discountValue,
    required this.isPercentage,
    required this.expiredDate,
    required this.minPurchaseAmount,
    this.maxDiscountValue,
    required this.type,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      couponId: json['couponId'] ?? '',
      couponName: json['couponName'] ?? 'No Name',
      couponImageUrl: json['couponImageUrl'] ?? '',
      discountValue: (json['discountValue'] as num).toDouble(),
      isPercentage: json['isPercentage'] ?? false,
      expiredDate: json['expiredDate'] != null
          ? (json['expiredDate'] as Timestamp).toDate()
          : DateTime.now(),
      minPurchaseAmount: (json['minPurchaseAmount'] as num).toDouble(),
      maxDiscountValue: json['maxDiscountValue'] != null
          ? (json['maxDiscountValue'] as num).toDouble()
          : null,
      type: json['type'] == 'order' ? CouponType.order : CouponType.shipping,
    );
  }
}

enum CouponType {
  order, // Giảm giá vào tổng tiền hàng
  shipping, // Giảm giá vào phí ship
}
