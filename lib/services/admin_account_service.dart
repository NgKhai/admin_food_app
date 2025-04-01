import 'package:admin_food_app/models/user_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  Future<UserInfo> getUserAccount(String userId) async {
    DocumentSnapshot doc = await _usersRef.doc(userId).get();
    return UserInfo.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<List<UserInfo>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserInfo.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<bool> createUser(UserInfo userInfo) async {
    try {
      await _firestore.collection('users').doc(userInfo.userId).set({
        'userId': userInfo.userId,
        'name': userInfo.name,
        'phone': userInfo.phone,
        'couponId': userInfo.couponIds,
        'fcmToken': userInfo.fcmToken,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserInfo userInfo) async {
    try {
      await _firestore.collection('users').doc(userInfo.userId).update({
        'name': userInfo.name,
        'phone': userInfo.phone,
        'couponId': userInfo.couponIds,
        'fcmToken': userInfo.fcmToken,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting total users count: $e');
      return 0;
    }
  }

  Future<List<UserInfo>> getUsersByCoupon(String couponId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('couponId', arrayContains: couponId)
          .get();

      return snapshot.docs.map((doc) => UserInfo.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting users by coupon: $e');
      return [];
    }
  }
}