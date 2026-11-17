import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryStore = <String, dynamic>{};
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';
  static const String _loginKey = 'is_logged_in';

  static Future<void> initialize() async {
    if (_prefs != null) {
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }

    await _createDefaultAdmin();
  }

  static Future<List<String>?> _readStringList(String key) async {
    await initialize();
    if (_prefs != null) {
      return _prefs!.getStringList(key);
    }

    final Object? value = _memoryStore[key];
    if (value is List<String>) {
      return value;
    }
    if (value is List) {
      return value.map((Object? item) => item.toString()).toList();
    }
    return null;
  }

  static Future<void> _writeStringList(String key, List<String> value) async {
    await initialize();
    if (_prefs != null) {
      await _prefs!.setStringList(key, value);
      return;
    }

    _memoryStore[key] = value;
  }

  static Future<String?> _readString(String key) async {
    await initialize();
    if (_prefs != null) {
      return _prefs!.getString(key);
    }

    return _memoryStore[key] as String?;
  }

  static Future<void> _writeString(String key, String? value) async {
    await initialize();
    if (_prefs != null) {
      if (value == null) {
        await _prefs!.remove(key);
      } else {
        await _prefs!.setString(key, value);
      }
      return;
    }

    if (value == null) {
      _memoryStore.remove(key);
    } else {
      _memoryStore[key] = value;
    }
  }

  static Future<bool> _readBool(String key) async {
    await initialize();
    if (_prefs != null) {
      return _prefs!.getBool(key) ?? false;
    }

    return _memoryStore[key] as bool? ?? false;
  }

  static Future<void> _writeBool(String key, bool value) async {
    await initialize();
    if (_prefs != null) {
      await _prefs!.setBool(key, value);
      return;
    }

    _memoryStore[key] = value;
  }

  static Future<void> _remove(String key) async {
    await initialize();
    if (_prefs != null) {
      await _prefs!.remove(key);
      return;
    }

    _memoryStore.remove(key);
  }

  static Future<List<UserModel>> _readUsers() async {
    try {
      final List<String> raw = await _readStringList(_usersKey) ?? <String>[];
      return raw.map((String item) {
        return UserModel.fromJson(jsonDecode(item) as Map<String, dynamic>);
      }).toList();
    } catch (_) {
      return <UserModel>[];
    }
  }

  static Future<void> _createDefaultAdmin() async {
    final List<UserModel> users = await _readUsers();

    final int adminIndex = users.indexWhere(
      (UserModel user) => user.email.trim().toLowerCase() == 'admin@gmail.com',
    );

    if (adminIndex < 0) {
      users.add(
        UserModel(
          fullName: 'Administrator',
          email: 'admin@gmail.com',
          phone: '0123456789',
          password: '123456',
          avatar: 'https://i.pravatar.cc/300',
          gender: 'Male',
          city: 'Ho Chi Minh',
          role: 'admin',
        ),
      );

      await _writeUsers(users);
      return;
    }

    final UserModel existingAdmin = users[adminIndex];
    if (existingAdmin.role.toLowerCase() != 'admin') {
      users[adminIndex] = UserModel(
        fullName: existingAdmin.fullName,
        email: existingAdmin.email,
        phone: existingAdmin.phone,
        password: existingAdmin.password,
        avatar: existingAdmin.avatar,
        gender: existingAdmin.gender,
        city: existingAdmin.city,
        role: 'admin',
      );
      await _writeUsers(users);
    }
  }

  static Future<void> _writeUsers(List<UserModel> users) async {
    final List<String> encoded = users
        .map((UserModel user) => jsonEncode(user.toJson()))
        .toList();
    await _writeStringList(_usersKey, encoded);
  }

  static Future<bool> register(UserModel user) async {
    try {
      final List<UserModel> users = await _readUsers();
      final String normalizedEmail = user.email.trim().toLowerCase();

      for (final UserModel existingUser in users) {
        if (existingUser.email.toLowerCase() == normalizedEmail) {
          return false;
        }
      }

      final UserModel newUser = UserModel(
        fullName: user.fullName.trim(),
        email: normalizedEmail,
        phone: user.phone.trim(),
        password: user.password,
        avatar: user.avatar.trim().isEmpty
            ? 'https://i.pravatar.cc/300'
            : user.avatar.trim(),
        gender: user.gender,
        city: user.city,
        role: user.role,
      );

      users.add(newUser);
      await _writeUsers(users);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    await _createDefaultAdmin();
    final List<UserModel> users = await _readUsers();

    for (final UserModel user in users) {
      if (user.email.trim().toLowerCase() == email.trim().toLowerCase() &&
          user.password == password) {
        await _writeBool(_loginKey, true);
        await _writeString(_currentUserKey, jsonEncode(user.toJson()));
        return true;
      }
    }

    return false;
  }

  static Future<UserModel?> currentUser() async {
    final String? raw = await _readString(_currentUserKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<bool> isLogin() async {
    return _readBool(_loginKey);
  }

  static Future<bool> isAdmin() async {
    final UserModel? user = await currentUser();
    return user?.role.toLowerCase() == 'admin';
  }

  static Future<void> logout() async {
    await _writeBool(_loginKey, false);
    await _remove(_currentUserKey);
  }

  static Future<bool> isExistEmail(String email) async {
    final List<UserModel> users = await _readUsers();
    return users.any(
      (UserModel user) => user.email.toLowerCase() == email.toLowerCase(),
    );
  }

  static Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final List<UserModel> users = await _readUsers();
    final int index = users.indexWhere(
      (UserModel user) => user.email.toLowerCase() == email.toLowerCase(),
    );
    if (index < 0) {
      return false;
    }

    users[index] = UserModel(
      fullName: users[index].fullName,
      email: users[index].email,
      phone: users[index].phone,
      password: newPassword,
      avatar: users[index].avatar,
      gender: users[index].gender,
      city: users[index].city,
      role: users[index].role,
    );

    await _writeUsers(users);
    return true;
  }

  static Future<List<UserModel>> getAllUsers() async {
    return await _readUsers();
  }

  static Future<bool> updateUser(UserModel user) async {
    final List<UserModel> users = await _readUsers();
    final int index = users.indexWhere(
      (UserModel u) => u.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (index >= 0) {
      users[index] = user;
      await _writeUsers(users);
      final UserModel? signedInUser = await currentUser();
      if (signedInUser?.email.toLowerCase() == user.email.toLowerCase()) {
        await _writeString(_currentUserKey, jsonEncode(user.toJson()));
      }
      return true;
    }
    return false;
  }

  static Future<bool> updateAccountDetails({
    required String currentEmail,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final String normalizedCurrentEmail = currentEmail.trim().toLowerCase();
    final String normalizedEmail = email.trim().toLowerCase();
    final UserModel? signedInUser = await currentUser();
    if (signedInUser?.email.toLowerCase() != normalizedCurrentEmail) {
      return false;
    }

    final List<UserModel> users = await _readUsers();
    final int index = users.indexWhere(
      (UserModel user) => user.email.toLowerCase() == normalizedCurrentEmail,
    );
    if (index < 0 ||
        users.any(
          (UserModel user) =>
              user.email.toLowerCase() == normalizedEmail &&
              user.email.toLowerCase() != normalizedCurrentEmail,
        )) {
      return false;
    }

    final UserModel oldUser = users[index];
    final UserModel updatedUser = UserModel(
      fullName: fullName.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      password: oldUser.password,
      avatar: oldUser.avatar,
      gender: oldUser.gender,
      city: oldUser.city,
      role: oldUser.role,
    );
    users[index] = updatedUser;
    await _writeUsers(users);
    await _writeString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    return true;
  }

  static Future<bool> changeCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    final UserModel? signedInUser = await currentUser();
    if (signedInUser?.email.toLowerCase() != normalizedEmail) {
      return false;
    }

    final List<UserModel> users = await _readUsers();
    final int index = users.indexWhere(
      (UserModel user) =>
          user.email.toLowerCase() == normalizedEmail &&
          user.password == currentPassword,
    );
    if (index < 0) {
      return false;
    }

    final UserModel oldUser = users[index];
    final UserModel updatedUser = UserModel(
      fullName: oldUser.fullName,
      email: oldUser.email,
      phone: oldUser.phone,
      password: newPassword,
      avatar: oldUser.avatar,
      gender: oldUser.gender,
      city: oldUser.city,
      role: oldUser.role,
    );
    users[index] = updatedUser;
    await _writeUsers(users);
    await _writeString(_currentUserKey, jsonEncode(updatedUser.toJson()));
    return true;
  }

  static Future<bool> deleteCurrentAccount({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    final UserModel? signedInUser = await currentUser();
    if (signedInUser?.email.toLowerCase() != normalizedEmail) {
      return false;
    }

    final List<UserModel> users = await _readUsers();
    final int index = users.indexWhere(
      (UserModel user) =>
          user.email.toLowerCase() == normalizedEmail &&
          user.password == password,
    );
    if (index < 0) {
      return false;
    }

    users.removeAt(index);
    await _writeUsers(users);
    await logout();
    return true;
  }

  static Future<bool> deleteUser(String email) async {
    final List<UserModel> users = await _readUsers();
    final int originalCount = users.length;
    users.removeWhere(
      (UserModel u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (users.length < originalCount) {
      await _writeUsers(users);
      return true;
    }
    return false;
  }
}
