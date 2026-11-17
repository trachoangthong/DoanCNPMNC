import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_assets.dart';
import '../../services/auth_service.dart';
import '../../services/shop_provider.dart';
import '../admin/admin_main_page.dart';
import '../main_pages/main_page.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _loadRememberMe();
  }

  Future<void> _restoreSession() async {
    final bool alreadyLoggedIn = await AuthService.isLogin();
    if (!mounted || !alreadyLoggedIn) {
      return;
    }

    final user = await AuthService.currentUser();
    if (!mounted) {
      return;
    }

    Provider.of<ShopProvider>(context, listen: false).refreshData();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext _) => user?.role.toLowerCase() == 'admin'
            ? const AdminMainPage()
            : const MainPage(),
      ),
    );
  }

  Future<void> _loadRememberMe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool remember = prefs.getBool('rememberMe') ?? false;

    if (remember) {
      emailController.text = prefs.getString('savedEmail') ?? '';
      passwordController.text = prefs.getString('savedPassword') ?? '';
    }

    if (!mounted) {
      return;
    }
    setState(() {
      rememberMe = remember;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isLoading = true);

    final bool success = await AuthService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }
    setState(() => isLoading = false);

    if (success) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('rememberMe', true);
        await prefs.setString('savedEmail', emailController.text.trim());
        await prefs.setString('savedPassword', passwordController.text.trim());
      } else {
        await prefs.remove('rememberMe');
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
      }

      if (mounted) {
        Provider.of<ShopProvider>(context, listen: false).refreshData();
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công'),
          backgroundColor: Colors.green,
        ),
      );

      final user = await AuthService.currentUser();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext _) => user?.role.toLowerCase() == 'admin'
              ? const AdminMainPage()
              : const MainPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email hoặc mật khẩu không đúng'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xfffef2f2), Color(0xfffff7ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      AppAssets.getImage('CellphoneS_Icon.png'),
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xffd70018),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chào mừng bạn quay trở lại',
                      style: TextStyle(color: Color(0xff6b7280)),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: rememberMe,
                      onChanged: (bool? value) {
                        setState(() => rememberMe = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ghi nhớ đăng nhập'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext _) =>
                                  const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Color(0xffd70018),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffd70018),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ĐĂNG NHẬP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Chưa có tài khoản? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext _) =>
                                    const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: Color(0xffd70018),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
