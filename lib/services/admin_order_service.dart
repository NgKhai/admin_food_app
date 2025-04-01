import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';

class AdminOrderService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef => _firestore.collection('orders');

  Stream<List<OrderProduct>> getOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              OrderProduct.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Giao thành công';
      case 'cancelled':
        return 'Đơn hàng hủy';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao';
      case 'pending':
        return 'Chờ xác nhận';
      case 'all':
        return 'Tất cả';
      default:
        return 'Lỗi';
    }
  }

  Future<OrderProduct?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderProduct.fromJson(doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  Future<List<OrderProduct>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderProduct.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  Future<List<OrderProduct>> getRecentOrders({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => OrderProduct.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recent orders: $e');
      return [];
    }
  }

  Future<bool> createOrder(OrderProduct order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toJson());
      return true;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  Future<bool> rateOrder(
      String orderId, int ratingBar, String? feedback) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'ratedBar': ratingBar,
        'feedback': feedback,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error rating order: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getOrderAnalytics() async {
    try {
      final ordersSnapshot = await _firestore.collection('orders').get();

      final totalOrders = ordersSnapshot.docs.length;
      final totalRevenue = ordersSnapshot.docs
          .fold(0.0, (sum, order) => sum + (order.data()['totalPrice'] ?? 0));

      // Product sales calculation
      final productSales = <String, num>{};
      for (var order in ordersSnapshot.docs) {
        final items = order.data()['listCartItem'] as List;
        for (var item in items) {
          final productId = item['productId'];
          productSales[productId] =
              (productSales[productId] ?? 0) + item['quantity'];
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'productSales': productSales,
      };
    } catch (e) {
      print('Error getting order analytics: $e');
      return {};
    }
  }
}
