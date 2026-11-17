import '../data/database_helper.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<int> send({
    required String title,
    required String body,
    String? recipientEmail,
  }) async {
    final String normalizedTitle = title.trim();
    final String normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) {
      throw ArgumentError('Tiêu đề và nội dung thông báo không được để trống.');
    }

    final currentUser = await AuthService.currentUser();
    if (currentUser == null || currentUser.role.toLowerCase() != 'admin') {
      throw StateError('Chỉ quản trị viên mới có thể gửi thông báo.');
    }

    final users = await AuthService.getAllUsers();
    final String? normalizedRecipient = recipientEmail?.trim().toLowerCase();
    final List<String> recipients;
    if (normalizedRecipient == null) {
      recipients = users
          .where((user) => user.role.toLowerCase() != 'admin')
          .map((user) => user.email.trim().toLowerCase())
          .toSet()
          .toList();
      if (recipients.isEmpty) {
        throw StateError('Hệ thống chưa có người dùng để nhận thông báo.');
      }
    } else {
      final isRegisteredUser = users.any(
        (user) =>
            user.email.trim().toLowerCase() == normalizedRecipient &&
            user.role.toLowerCase() != 'admin',
      );
      if (!isRegisteredUser) {
        throw ArgumentError('Không tìm thấy người dùng nhận thông báo.');
      }
      recipients = <String>[normalizedRecipient];
    }

    return DatabaseHelper.instance.insertNotification(
      AppNotification(
        title: normalizedTitle,
        body: normalizedBody,
        senderEmail: currentUser.email.trim().toLowerCase(),
        targetEmail: normalizedRecipient,
        createdAt: DateTime.now(),
      ),
      recipientEmails: recipients,
    );
  }

  static Future<List<AppNotification>> getInbox(String userEmail) {
    return DatabaseHelper.instance.getNotificationsForUser(userEmail);
  }

  static Future<int> getUnreadCount(String userEmail) {
    return DatabaseHelper.instance.countUnreadNotifications(userEmail);
  }

  static Future<void> markAsRead({
    required int notificationId,
    required String userEmail,
  }) {
    return DatabaseHelper.instance.markNotificationRead(
      notificationId: notificationId,
      userEmail: userEmail,
    );
  }

  static Future<List<AppNotification>> getSentByAdmin(String adminEmail) {
    return DatabaseHelper.instance.getNotificationsSentBy(adminEmail);
  }
}
