import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  late Future<_AdminNotificationData> _dataFuture;
  bool _sendToAll = true;
  bool _isSending = false;
  String? _selectedRecipientEmail;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<_AdminNotificationData> _loadData() async {
    final admin = await AuthService.currentUser();
    if (admin == null || admin.role.toLowerCase() != 'admin') {
      throw StateError('Chỉ quản trị viên mới được quản lý thông báo.');
    }

    final allUsers = await AuthService.getAllUsers();
    final users = allUsers
        .where((user) => user.role.toLowerCase() != 'admin')
        .toList();
    final notifications = await NotificationService.getSentByAdmin(admin.email);
    return _AdminNotificationData(users: users, notifications: notifications);
  }

  Future<void> _send(_AdminNotificationData data) async {
    if (!_formKey.currentState!.validate()) return;

    final bool sendToAll = _sendToAll;
    final selectedEmail = _selectedRecipientEmail;
    final bool hasSelectedUser = data.users.any(
      (user) => user.email.trim().toLowerCase() == selectedEmail?.toLowerCase(),
    );
    final String? recipientEmail = sendToAll
        ? null
        : (hasSelectedUser ? selectedEmail : null) ??
              (data.users.isEmpty ? null : data.users.first.email);
    if (!sendToAll && recipientEmail == null) {
      _showMessage('Hệ thống chưa có người dùng để nhận thông báo.');
      return;
    }

    setState(() => _isSending = true);
    try {
      await NotificationService.send(
        title: _titleController.text,
        body: _bodyController.text,
        recipientEmail: recipientEmail,
      );
      _titleController.clear();
      _bodyController.clear();
      if (!mounted) return;
      setState(() => _dataFuture = _loadData());
      _showMessage(
        sendToAll
            ? 'Đã gửi thông báo đến toàn bộ người dùng.'
            : 'Đã gửi thông báo đến người dùng được chọn.',
      );
    } on DatabaseException catch (error) {
      _showMessage('Không thể lưu thông báo: $error');
    } on ArgumentError catch (error) {
      _showMessage('Thông tin gửi thông báo không hợp lệ: $error');
    } on StateError catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminNotificationData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Không thể tải dữ liệu thông báo: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final selectedRecipientEmail =
            data.users.any(
              (user) =>
                  user.email.trim().toLowerCase() ==
                  _selectedRecipientEmail?.toLowerCase(),
            )
            ? _selectedRecipientEmail
            : (data.users.isEmpty ? null : data.users.first.email);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tạo thông báo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập tiêu đề.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bodyController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung thông báo',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập nội dung.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Người nhận',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Toàn bộ người dùng'),
                        selected: _sendToAll,
                        onSelected: _isSending
                            ? null
                            : (selected) {
                                if (selected) setState(() => _sendToAll = true);
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Chọn một người dùng'),
                        selected: !_sendToAll,
                        onSelected: _isSending
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() => _sendToAll = false);
                                }
                              },
                      ),
                    ],
                  ),
                  if (!_sendToAll) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRecipientEmail,
                      decoration: const InputDecoration(
                        labelText: 'Chọn người dùng',
                        border: OutlineInputBorder(),
                      ),
                      items: data.users
                          .map(
                            (UserModel user) => DropdownMenuItem<String>(
                              value: user.email,
                              child: Text(
                                '${user.fullName} - ${user.email}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: data.users.isEmpty || _isSending
                          ? null
                          : (email) {
                              setState(() => _selectedRecipientEmail = email);
                            },
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSending ? null : () => _send(data),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Đang gửi...' : 'Gửi thông báo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: appRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Thông báo đã gửi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (data.notifications.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có thông báo nào được gửi.'),
                ),
              )
            else
              ...data.notifications.map(
                (notification) =>
                    _SentNotificationCard(notification: notification),
              ),
          ],
        );
      },
    );
  }
}

class _AdminNotificationData {
  final List<UserModel> users;
  final List<AppNotification> notifications;

  const _AdminNotificationData({
    required this.users,
    required this.notifications,
  });
}

class _SentNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _SentNotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final recipient = notification.targetEmail ?? 'Toàn bộ người dùng';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xffffeef0),
          child: Icon(Icons.notifications, color: appRed),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
              const SizedBox(height: 5),
              Text(
                recipient,
                style: const TextStyle(color: Color(0xff7b8795), fontSize: 12),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                style: const TextStyle(color: Color(0xff7b8795), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
