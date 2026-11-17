import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class CartService {
  static SharedPreferences? _prefs;
  static const String _cartKey = 'cart_items';

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Product>> getCart() async {
    try {
      await initialize();
      final raw = _prefs!.getStringList(_cartKey) ?? <String>[];
      return raw
          .map((item) => Product.fromJson(jsonDecode(item)))
          .toList(growable: true);
    } catch (_) {
      return <Product>[];
    }
  }

  static Future<int> getCartCount() async {
    final cart = await getCart();
    return cart.length;
  }

  static Future<void> addProduct(Product product) async {
    try {
      await initialize();
      final cart = await getCart();
      final exists = cart.any((item) => item.name == product.name);
      if (!exists) {
        cart.add(product);
        final encoded = cart.map((item) => jsonEncode(item.toJson())).toList();
        await _prefs!.setStringList(_cartKey, encoded);
      }
    } catch (_) {}
  }

  static Future<void> clearCart() async {
    try {
      await initialize();
      await _prefs!.remove(_cartKey);
    } catch (_) {}
  }
}
