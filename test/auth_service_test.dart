import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.initialize();
    await AuthService.logout();
  });

  test('register adds a new user and prevents duplicate emails', () async {
    final user = UserModel(
      fullName: 'Test User',
      email: 'test@example.com',
      phone: '0123456789',
      password: 'password123',
      avatar: '',
      gender: 'Male',
      city: 'Ho Chi Minh',
      address: '12 Nguyen Hue',
      role: 'user',
    );

    expect(await AuthService.register(user), isTrue);
    expect(await AuthService.register(user), isFalse);
    expect(await AuthService.isExistEmail('test@example.com'), isTrue);
    expect(
      (await AuthService.getAllUsers())
          .firstWhere((UserModel item) => item.email == user.email)
          .address,
      '12 Nguyen Hue',
    );
  });

  test('register preserves admin role for admin accounts', () async {
    final admin = UserModel(
      fullName: 'Admin User',
      email: 'admin@example.com',
      phone: '0987654321',
      password: 'admin123',
      avatar: '',
      gender: 'Female',
      city: 'Ha Noi',
      role: 'admin',
    );

    expect(await AuthService.register(admin), isTrue);
    expect(
      await AuthService.login(email: admin.email, password: admin.password),
      isTrue,
    );

    final currentUser = await AuthService.currentUser();
    expect(currentUser, isNotNull);
    expect(currentUser!.role, 'admin');
    expect(await AuthService.isAdmin(), isTrue);
  });

  test('default admin can log in and keeps the admin role', () async {
    final List<UserModel> users = await AuthService.getAllUsers();
    final UserModel admin = users.firstWhere(
      (UserModel user) => user.email == 'admin@gmail.com',
    );

    expect(
      await AuthService.login(email: admin.email, password: '123456'),
      isTrue,
    );
    expect((await AuthService.currentUser())?.role, 'admin');
  });

  test('default admin role is restored before login', () async {
    final List<UserModel> users = await AuthService.getAllUsers();
    final UserModel admin = users.firstWhere(
      (UserModel user) => user.email == 'admin@gmail.com',
    );
    await AuthService.updateUser(
      UserModel(
        fullName: admin.fullName,
        email: admin.email,
        phone: admin.phone,
        password: admin.password,
        avatar: admin.avatar,
        gender: admin.gender,
        city: admin.city,
        role: 'user',
      ),
    );

    expect(
      await AuthService.login(email: admin.email, password: admin.password),
      isTrue,
    );
    expect((await AuthService.currentUser())?.role, 'admin');
  });

  test(
    'account details can be edited without losing the active session',
    () async {
      final user = UserModel(
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '0123456789',
        password: 'password123',
        avatar: '',
        gender: 'Male',
        city: 'Ho Chi Minh',
        address: '12 Nguyen Hue',
      );
      await AuthService.register(user);
      await AuthService.login(email: user.email, password: user.password);

      expect(
        await AuthService.updateAccountDetails(
          currentEmail: user.email,
          fullName: 'Updated User',
          email: 'updated@example.com',
          phone: '0987654321',
          address: '56 Le Loi',
        ),
        isTrue,
      );
      expect(
        await AuthService.updateAccountDetails(
          currentEmail: 'updated@example.com',
          fullName: 'Updated User',
          email: 'admin@gmail.com',
          phone: '0987654321',
          address: '56 Le Loi',
        ),
        isFalse,
      );

      final currentUser = await AuthService.currentUser();
      expect(currentUser?.fullName, 'Updated User');
      expect(currentUser?.email, 'updated@example.com');
      expect(currentUser?.phone, '0987654321');
      expect(currentUser?.address, '56 Le Loi');
    },
  );

  test(
    'password can be changed and account deletion ends the session',
    () async {
      final user = UserModel(
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '0123456789',
        password: 'password123',
        avatar: '',
        gender: 'Male',
        city: 'Ho Chi Minh',
      );
      await AuthService.register(user);
      await AuthService.login(email: user.email, password: user.password);

      expect(
        await AuthService.changeCurrentPassword(
          email: user.email,
          currentPassword: 'wrong-password',
          newPassword: 'new-password',
        ),
        isFalse,
      );
      expect(
        await AuthService.changeCurrentPassword(
          email: user.email,
          currentPassword: user.password,
          newPassword: 'new-password',
        ),
        isTrue,
      );
      expect(
        await AuthService.login(email: user.email, password: 'new-password'),
        isTrue,
      );

      expect(
        await AuthService.deleteCurrentAccount(
          email: user.email,
          password: 'new-password',
        ),
        isTrue,
      );
      expect(await AuthService.isLogin(), isFalse);
      expect(await AuthService.isExistEmail(user.email), isFalse);
    },
  );
}
