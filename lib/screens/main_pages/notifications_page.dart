import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final user = await AuthService.currentUser();
    if (user == null || user.role.toLowerCase() == 'admin') {
      throw StateError('Vui lòng đăng nhập bằng tài khoản người dùng.');
    }
    return NotificationService.getInbox(user.email);
  }

  Future<void> _openNotification(AppNotification notification) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(child: Text(notification.body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );

    final notificationId = notification.id;
    if (!mounted || notificationId == null || notification.isRead) return;

    try {
      final user = await AuthService.currentUser();
      if (user == null) {
        throw StateError('Phiên đăng nhập đã kết thúc.');
      }
      await NotificationService.markAsRead(
        notificationId: notificationId,
        userEmail: user.email,
      );
      if (mounted) {
        setState(() => _notificationsFuture = _loadNotifications());
      }
    } on DatabaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật trạng thái đã đọc: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Không thể tải thông báo: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Bạn chưa có thông báo nào.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                color: notification.isRead
                    ? Colors.white
                    : const Color(0xfffff5f5),
                child: ListTile(
                  onTap: () => _openNotification(notification),
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead
                        ? const Color(0xfff1f3f5)
                        : const Color(0xffffe2e5),
                    child: Icon(
                      notification.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: appRed,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(notification.createdAt),
                          style: const TextStyle(
                            color: Color(0xff7b8795),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: notification.isRead
                      ? null
                      : const Icon(Icons.circle, color: appRed, size: 10),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
