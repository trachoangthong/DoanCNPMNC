import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/database_helper.dart';
import 'package:flutter_application_1/models/order.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final db = await DatabaseHelper.instance.database;
    await db.delete('Favorite');
    await db.delete('Cart');
    await db.delete('OrderItems');
    await db.delete('Orders');
    await db.delete('Product');
    await db.delete('Category');
  });

  test(
    'adding a product keeps it in the list after concurrent refreshes',
    () async {
      final ShopProvider shop = ShopProvider();
      final Future<void> previousRefresh = shop.refreshData();

      await shop.addProduct(
        const Product(
          name: 'Sản phẩm mới',
          image: 'https://example.com/product.jpg',
          price: 100000,
          category: 'Điện thoại',
          description: 'Sản phẩm kiểm tra',
        ),
      );
      await previousRefresh;

      expect(
        shop.products.map((Product product) => product.name),
        contains('Sản phẩm mới'),
      );
    },
  );

  test('refresh completing after disposal does not notify listeners', () async {
    final ShopProvider shop = ShopProvider();
    final Future<void> refresh = shop.refreshData();

    shop.dispose();

    await expectLater(refresh, completes);
  });

  test('placing an order stores the total after coupon discount', () async {
    final ShopProvider shop = ShopProvider();
    try {
      final int productId = await shop.addProduct(
        const Product(
          name: 'Sản phẩm giảm giá',
          image: 'https://example.com/product.jpg',
          price: 100000,
          category: 'Điện thoại',
          description: 'Sản phẩm kiểm tra giảm giá',
        ),
      );
      final Product product = shop.products.singleWhere(
        (Product product) => product.id == productId,
      );
      await shop.addToCart(product);

      final bool placed = await shop.placeOrder(discountAmount: 25000);

      expect(placed, isTrue);
      final orders = await DatabaseHelper.instance.getOrders();
      expect(orders.single.total, 75000);
    } finally {
      shop.dispose();
    }
  });

  test('users see only their own orders while admins see all orders', () async {
    final List<UserModel> users = <UserModel>[
      UserModel(
        fullName: 'Người dùng A',
        email: 'user-a@example.com',
        phone: '0900000001',
        password: 'password-a',
        avatar: '',
        gender: '',
        city: '',
      ),
      UserModel(
        fullName: 'Người dùng B',
        email: 'user-b@example.com',
        phone: '0900000002',
        password: 'password-b',
        avatar: '',
        gender: '',
        city: '',
      ),
      UserModel(
        fullName: 'Quản trị viên',
        email: 'orders-admin@example.com',
        phone: '0900000003',
        password: 'password-admin',
        avatar: '',
        gender: '',
        city: '',
        role: 'admin',
      ),
    ];

    for (final UserModel user in users) {
      expect(await AuthService.register(user), isTrue);
    }

    for (final String email in <String>[
      'user-a@example.com',
      'user-b@example.com',
    ]) {
      await DatabaseHelper.instance.insertOrder(
        OrderModel(
          date: DateTime(2026, 11, 16),
          total: 100000,
          status: OrderStatus.pending,
          customerName: email,
          userEmail: email,
        ),
      );
    }

    final ShopProvider shop = ShopProvider();
    try {
      expect(
        await AuthService.login(
          email: 'user-a@example.com',
          password: 'password-a',
        ),
        isTrue,
      );
      await shop.refreshData();
      expect(shop.orders.map((OrderModel order) => order.userEmail), <String?>[
        'user-a@example.com',
      ]);

      expect(
        await AuthService.login(
          email: 'user-b@example.com',
          password: 'password-b',
        ),
        isTrue,
      );
      await shop.refreshData();
      expect(shop.orders.map((OrderModel order) => order.userEmail), <String?>[
        'user-b@example.com',
      ]);

      expect(
        await AuthService.login(
          email: 'orders-admin@example.com',
          password: 'password-admin',
        ),
        isTrue,
      );
      await shop.refreshData();
      expect(shop.orders, hasLength(2));
    } finally {
      shop.dispose();
    }
  });
}
