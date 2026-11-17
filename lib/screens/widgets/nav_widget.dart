import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  static const Color red = Color(0xffd70018);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      indicatorColor: red.withValues(alpha: 0.08),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: <NavigationDestination>[
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: red),
          label: 'Trang chủ',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: red),
          label: 'Danh mục',
        ),
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront, color: red),
          label: 'Cửa hàng',
        ),
        NavigationDestination(
          icon: _CartIcon(cartCount: cartCount, selected: false),
          selectedIcon: _CartIcon(cartCount: cartCount, selected: true),
          label: 'Giỏ hàng',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: red),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}

class _CartIcon extends StatelessWidget {
  final int cartCount;
  final bool selected;
  static const Color red = Color(0xffd70018);

  const _CartIcon({required this.cartCount, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(
          Icons.shopping_cart_outlined,
          color: selected ? red : Colors.grey.shade700,
        ),
        if (cartCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  cartCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
