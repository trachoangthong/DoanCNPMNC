import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_provider.dart';
import '../auth_pages/login_page.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key, required this.user});

  final UserModel user;

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bool updated = await AuthService.updateAccountDetails(
        currentEmail: widget.user.email,
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );
      if (!mounted) {
        return;
      }
      if (!updated) {
        _showMessage(
          'Email này đã được sử dụng hoặc tài khoản không còn tồn tại.',
        );
        return;
      }

      await Provider.of<ShopProvider>(context, listen: false).refreshData();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      debugPrint('Không thể cập nhật thông tin người dùng: $error');
      if (mounted) {
        _showMessage('Không thể lưu thông tin. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          _ChangePasswordDialog(email: widget.user.email),
    );
    if (changed == true && mounted) {
      _showMessage('Đổi mật khẩu thành công.');
    }
  }

  Future<void> _deleteAccount() async {
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bool deleted = await AuthService.deleteCurrentAccount(
        email: widget.user.email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      if (!deleted) {
        _showMessage('Mật khẩu không đúng hoặc tài khoản không còn tồn tại.');
        return;
      }

      await Provider.of<ShopProvider>(context, listen: false).refreshData();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (BuildContext _) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      debugPrint('Không thể xóa tài khoản: $error');
      if (mounted) {
        _showMessage('Không thể xóa tài khoản. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xffffe4e6),
                  child: Icon(Icons.person, size: 46, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) =>
                    _validateRequired(value, 'họ tên'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  final String? requiredError = _validateRequired(
                    value,
                    'email',
                  );
                  if (requiredError != null) {
                    return requiredError;
                  }
                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(value!.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) =>
                    _validateRequired(value, 'số điện thoại'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhận hàng',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (String? value) =>
                    _validateRequired(value, 'địa chỉ'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _saveDetails,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu thay đổi'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _changePassword,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Đổi mật khẩu'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isSaving ? null : _deleteAccount,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Xóa tài khoản',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.email});

  final String email;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final bool changed = await AuthService.changeCurrentPassword(
        email: widget.email,
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) {
        return;
      }
      if (!changed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu hiện tại không đúng.')),
        );
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Không thể đổi mật khẩu: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đổi mật khẩu. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _currentPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                ),
                validator: (String? value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập mật khẩu hiện tại'
                    : null,
              ),
              TextFormField(
                controller: _newPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (String? value) {
                  if (value == null || value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                ),
                validator: (String? value) => value != _newPassword.text
                    ? 'Mật khẩu xác nhận không khớp'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xóa tài khoản?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Thao tác này không thể hoàn tác. Nhập mật khẩu để xác nhận xóa tài khoản.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            if (_passwordController.text.isNotEmpty) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          child: const Text('Xóa tài khoản'),
        ),
      ],
    );
  }
}
