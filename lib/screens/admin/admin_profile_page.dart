import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/shop_provider.dart';
import '../../models/user_model.dart';
import '../auth_pages/login_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext _) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất khỏi tài khoản Admin?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appRed, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await AuthService.logout();
    if (context.mounted) {
      Provider.of<ShopProvider>(context, listen: false).refreshData();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (BuildContext _) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _item({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: <Widget>[
          CircleAvatar(radius: 22, backgroundColor: const Color(0xfffde8ea), child: Icon(icon, color: appRed)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f2f3),
      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
        centerTitle: true,
        backgroundColor: appRed,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService.currentUser(),
        builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
          final UserModel? user = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  color: appRed,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(user?.avatar ?? 'https://i.pravatar.cc/300'),
                      onBackgroundImageError: (Object _, StackTrace? __) {
                        debugPrint('Error loading avatar');
                      },
                      child: user?.avatar == null ? const Icon(Icons.person, size: 45, color: appRed) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? "Quản trị viên",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    Text(user?.role.toUpperCase() ?? "ADMIN", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _item(icon: Icons.person, title: "Họ và tên", value: user?.fullName ?? "N/A"),
                    _item(icon: Icons.email_outlined, title: "Email", value: user?.email ?? "N/A"),
                    _item(icon: Icons.phone, title: "Số điện thoại", value: user?.phone ?? "N/A"),
                    _item(icon: Icons.location_city, title: "Thành phố", value: user?.city ?? "N/A"),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          _logout(context);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
