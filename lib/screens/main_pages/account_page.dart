import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/shop_provider.dart';
import '../../models/user_model.dart';
import '../auth_pages/login_page.dart';
import '../admin/admin_main_page.dart';
import 'user_details_page.dart';
import 'order_history_page.dart';
import 'favorites_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService.currentUser();
  }

  Future<void> _openUserDetails(UserModel user) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => UserDetailsPage(user: user),
      ),
    );
    if (updated == true && mounted) {
      setState(() {
        _userFuture = AuthService.currentUser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (BuildContext context, AsyncSnapshot<UserModel?> snapshot) {
        final UserModel? user = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Tài khoản'), elevation: 0),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                _buildHeader(user),
                const SizedBox(height: 20),
                _buildMenu(context, user),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              user?.avatar ?? 'https://i.pravatar.cc/300',
            ),
            onBackgroundImageError: (Object exception, StackTrace? stackTrace) {
              debugPrint('Error loading avatar: $exception');
            },
            child: user?.avatar == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user?.fullName ?? 'Khách',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          if (user?.role == 'admin')
            _menuItem(Icons.admin_panel_settings, 'Trang quản trị', () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const AdminMainPage(),
                ),
              );
            }),
          _menuItem(Icons.history, 'Lịch sử đơn hàng', () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext _) => const OrderHistoryPage(),
              ),
            );
          }),
          _menuItem(Icons.favorite_border, 'Sản phẩm yêu thích', () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext _) => const FavoritesPage(),
              ),
            );
          }),
          if (user != null)
            _menuItem(
              Icons.person_outline,
              'Chi tiết người dùng',
              () => _openUserDetails(user),
            ),
          const Divider(),
          _menuItem(Icons.logout, 'Đăng xuất', () async {
            await AuthService.logout();
            if (context.mounted) {
              Provider.of<ShopProvider>(context, listen: false).refreshData();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const LoginPage(),
                ),
                (Route<dynamic> route) => false,
              );
            }
          }, textColor: Colors.red),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
