import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../services/auth_service.dart';
import '../admin/admin_main_page.dart';
import '../main_pages/main_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double progress = 0;
  Timer? timer;
  bool isNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    startLoading();
  }

  Future<void> _checkExistingSession() async {
    final alreadyLoggedIn = await AuthService.isLogin();
    if (!mounted || !alreadyLoggedIn) return;

    isNavigated = true;
    timer?.cancel();

    final user = await AuthService.currentUser();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user?.role.toLowerCase() == 'admin'
            ? const AdminMainPage()
            : const MainPage(),
      ),
    );
  }

  void startLoading() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        progress += 0.02;
      });

      if (progress >= 1) {
        t.cancel();
        goToLogin();
      }
    });
  }

  void goToLogin() {
    if (isNavigated) return;
    isNavigated = true;
    timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffd70018), Color(0xfff97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.getImage('CellphoneS_Icon.png'),
                    width: 112,
                    height: 112,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CellphoneS',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Săn deal công nghệ chất mỗi ngày',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).toInt()} %',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 180,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: goToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xffd70018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Tiếp tục'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
