import 'package:dio/dio.dart';

import 'admin_account_service.dart';

class NotificationService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000';

  // Send notification to a single user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/send-notification',
        data: {
          'userId': userId,
          'title': title,
          'body': body,
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Send notification to multiple users
  Future<Map<String, bool>> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
  }) async {
    Map<String, bool> results = {};

    for (String userId in userIds) {
      final success = await sendNotification(
        userId: userId,
        title: title,
        body: body,
      );
      results[userId] = success;
    }

    return results;
  }

  // Send notification to all users with a specific coupon
  Future<bool> sendNotificationToCouponHolders({
    required String couponId,
    required String title,
    required String body,
    required AdminAccountService accountService,
  }) async {
    try {
      // Get all users who have this coupon
      final users = await accountService.getUsersByCoupon(couponId);

      if (users.isEmpty) {
        return false;
      }

      // Send notification to all users who have this coupon
      for (var user in users) {
        await sendNotification(
          userId: user.userId,
          title: title,
          body: body,
        );
      }

      return true;
    } catch (e) {
      print('Error sending notification to coupon holders: $e');
      return false;
    }
  }

  // Send notification to all users
  Future<bool> sendNotificationToAllUsers({
    required String title,
    required String body,
    required AdminAccountService accountService,
  }) async {
    try {
      // Get all users
      final users = await accountService.getAllUsers();

      if (users.isEmpty) {
        return false;
      }

      // Send notification to all users
      for (var user in users) {
        await sendNotification(
          userId: user.userId,
          title: title,
          body: body,
        );
      }

      return true;
    } catch (e) {
      print('Error sending notification to all users: $e');
      return false;
    }
  }
}