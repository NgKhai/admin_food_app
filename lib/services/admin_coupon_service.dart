import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _couponCollection = 'coupons';
  CollectionReference get _couponsRef => _firestore.collection('coupons');


  // Create a new coupon
  Future<String?> createCoupon(Coupon coupon) async {
    try {
      await _firestore.collection(_couponCollection).doc(coupon.couponId).set({
        'couponId': coupon.couponId,
        'couponName': coupon.couponName,
        'couponImageUrl': coupon.couponImageUrl,
        'discountValue': coupon.discountValue,
        'isPercentage': coupon.isPercentage,
        'expiredDate': coupon.expiredDate,
        'minPurchaseAmount': coupon.minPurchaseAmount,
        'maxDiscountValue': coupon.maxDiscountValue,
        'type': coupon.type == CouponType.order ? 'order' : 'shipping',
      });
      return coupon.couponId;
    } catch (e) {
      print('Error creating coupon: $e');
      return null;
    }
  }

  // Read all coupons
  Stream<List<Coupon>> getCoupons() {
    return _firestore.collection(_couponCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Coupon.fromJson({
      ...doc.data(),
      'id': doc.id,
    }))
        .toList());
  }

  // Update a coupon
  Future<bool> updateCoupon(String id, Coupon coupon) async {
    try {
      await _firestore.collection(_couponCollection).doc(id).update({
        'couponId': coupon.couponId,
        'couponName': coupon.couponName,
        'couponImageUrl': coupon.couponImageUrl,
        'discountValue': coupon.discountValue,
        'isPercentage': coupon.isPercentage,
        'expiredDate': coupon.expiredDate,
        'minPurchaseAmount': coupon.minPurchaseAmount,
        'maxDiscountValue': coupon.maxDiscountValue,
        'type': coupon.type == CouponType.order ? 'order' : 'shipping',
      });
      return true;
    } catch (e) {
      print('Error updating coupon: $e');
      return false;
    }
  }

  // Delete a coupon
  Future<bool> deleteCoupon(String id) async {
    try {
      await _firestore.collection(_couponCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting coupon: $e');
      return false;
    }
  }

  Future<List<Coupon>> getAllCoupons() async {
    try {
      final snapshot = await _couponsRef.get();
      return snapshot.docs
          .map((doc) => Coupon.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all coupons: $e');
      return [];
    }
  }

  Future<Coupon?> getCouponById(String couponId) async {
    try {
      final doc = await _couponsRef.doc(couponId).get();
      if (doc.exists) {
        return Coupon.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting coupon by ID: $e');
      return null;
    }
  }

  Future<List<Coupon>> getCouponsByIds(List<String> couponIds) async {
    try {
      if (couponIds.isEmpty) {
        return [];
      }

      // Firestore has limitations on 'in' queries, so we'll handle it in batches
      const int batchSize = 10;
      List<Coupon> results = [];

      for (int i = 0; i < couponIds.length; i += batchSize) {
        final end = (i + batchSize < couponIds.length) ? i + batchSize : couponIds.length;
        final batch = couponIds.sublist(i, end);

        final snapshot = await _couponsRef
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        results.addAll(snapshot.docs
            .map((doc) => Coupon.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
      }

      return results;
    } catch (e) {
      print('Error getting coupons by IDs: $e');
      return [];
    }
  }

  Future<List<Coupon>> getActiveCoupons() async {
    try {
      final now = DateTime.now();
      final snapshot = await _couponsRef
          .where('expiredDate', isGreaterThan: Timestamp.fromDate(now))
          .get();

      return snapshot.docs
          .map((doc) => Coupon.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting active coupons: $e');
      return [];
    }
  }

  Future<List<Coupon>> getExpiredCoupons() async {
    try {
      final now = DateTime.now();
      final snapshot = await _couponsRef
          .where('expiredDate', isLessThan: Timestamp.fromDate(now))
          .get();

      return snapshot.docs
          .map((doc) => Coupon.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting expired coupons: $e');
      return [];
    }
  }
}