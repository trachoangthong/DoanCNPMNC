import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/database_helper.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await AuthService.initialize();
  });

  setUp(() async {
    await AuthService.logout();
    final Database db = await DatabaseHelper.instance.database;
    await db.delete('NotificationReads');
    await db.delete('Notifications');
  });

  test('admin can broadcast or target users and reads are per user', () async {
    final firstUser = UserModel(
      fullName: 'First User',
      email: 'first@example.com',
      phone: '0123456789',
      password: 'password',
      avatar: '',
      gender: 'Other',
      city: 'Ho Chi Minh',
    );
    final secondUser = UserModel(
      fullName: 'Second User',
      email: 'second@example.com',
      phone: '0987654321',
      password: 'password',
      avatar: '',
      gender: 'Other',
      city: 'Ho Chi Minh',
    );
    expect(await AuthService.register(firstUser), isTrue);
    expect(await AuthService.register(secondUser), isTrue);
    expect(
      await AuthService.login(email: 'admin@gmail.com', password: '123456'),
      isTrue,
    );

    await NotificationService.send(
      title: 'Thông báo chung',
      body: 'Nội dung gửi cho mọi người.',
    );
    await NotificationService.send(
      title: 'Thông báo riêng',
      body: 'Nội dung gửi cho người thứ nhất.',
      recipientEmail: firstUser.email,
    );
    final futureUser = UserModel(
      fullName: 'Future User',
      email: 'future@example.com',
      phone: '0111222333',
      password: 'password',
      avatar: '',
      gender: 'Other',
      city: 'Ho Chi Minh',
    );
    expect(await AuthService.register(futureUser), isTrue);

    final firstInbox = await NotificationService.getInbox(firstUser.email);
    final secondInbox = await NotificationService.getInbox(secondUser.email);
    final futureInbox = await NotificationService.getInbox(futureUser.email);
    expect(firstInbox, hasLength(2));
    expect(secondInbox, hasLength(1));
    expect(futureInbox, isEmpty);
    expect(secondInbox.single.title, 'Thông báo chung');
    expect(await NotificationService.getUnreadCount(firstUser.email), 2);

    await NotificationService.markAsRead(
      notificationId: firstInbox.first.id!,
      userEmail: firstUser.email,
    );
    expect(await NotificationService.getUnreadCount(firstUser.email), 1);
    expect(await NotificationService.getUnreadCount(secondUser.email), 1);

    await AuthService.logout();
    expect(
      await AuthService.login(
        email: firstUser.email,
        password: firstUser.password,
      ),
      isTrue,
    );
    expect(
      () => NotificationService.send(title: 'Không hợp lệ', body: 'Nội dung'),
      throwsA(isA<StateError>()),
    );
  });
}
