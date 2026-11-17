import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/nav_widget.dart';
import 'account_page.dart';
import 'cart_page.dart';
import 'category_page.dart';
import 'home_page.dart';
import 'store_page.dart';
import '../../services/shop_provider.dart';
import '../../models/category.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  Category? selectedCategory;
  final GlobalKey<CartPageState> cartKey = GlobalKey<CartPageState>();

  List<Widget> get pages => [
    HomePage(onCategorySelected: _showCategory),
    CategoryPage(category: selectedCategory),
    const StorePage(),
    CartPage(key: cartKey),
    const AccountPage(),
  ];

  void _showCategory(Category category) {
    setState(() {
      selectedCategory = category;
      currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        cartCount: Provider.of<ShopProvider>(context).cartCount,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (index == 3) {
            cartKey.currentState?.refreshCart();
          }
        },
      ),
    );
  }
}
