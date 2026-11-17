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
    await db.delete('ProductReviews');
    await db.delete('Favorite');
    await db.delete('Cart');
    await db.delete('OrderItems');
    await db.delete('Orders');
    await db.delete('Product');
    await db.delete('Category');
  });

  test(
    'users can review a purchased product once its order is delivered',
    () async {
      final UserModel user = UserModel(
        fullName: 'Người đánh giá',
        email: 'reviewer@example.com',
        phone: '0900000000',
        password: 'password',
        avatar: '',
        gender: '',
        city: '',
      );
      expect(await AuthService.register(user), isTrue);
      final UserModel otherUser = UserModel(
        fullName: 'Người khác',
        email: 'other-reviewer@example.com',
        phone: '0900000001',
        password: 'other-password',
        avatar: '',
        gender: '',
        city: '',
      );
      final UserModel admin = UserModel(
        fullName: 'Quản trị viên',
        email: 'review-admin@example.com',
        phone: '0900000002',
        password: 'admin-password',
        avatar: '',
        gender: '',
        city: '',
        role: 'admin',
      );
      expect(await AuthService.register(otherUser), isTrue);
      expect(await AuthService.register(admin), isTrue);
      expect(
        await AuthService.login(email: user.email, password: user.password),
        isTrue,
      );

      final ShopProvider shop = ShopProvider();
      try {
        final int productId = await shop.addProduct(
          const Product(
            name: 'Sản phẩm được đánh giá',
            image: 'https://example.com/product.jpg',
            price: 100000,
            category: 'Điện thoại',
            description: 'Sản phẩm kiểm tra',
          ),
        );
        final Product product = shop.products.singleWhere(
          (Product product) => product.id == productId,
        );
        await shop.addToCart(product);
        expect(await shop.placeOrder(), isTrue);

        final int orderId = shop.orders.single.id!;
        expect(
          await shop.addProductReview(
            orderId: orderId,
            productId: productId,
            rating: 5,
            productName: product.name,
            comment: 'Chưa giao hàng',
          ),
          isFalse,
        );

        await shop.updateOrderStatus(orderId, OrderStatus.delivered);
        expect(
          await AuthService.login(
            email: otherUser.email,
            password: otherUser.password,
          ),
          isTrue,
        );
        expect(
          await shop.addProductReview(
            orderId: orderId,
            productId: productId,
            rating: 5,
            productName: product.name,
            comment: 'Không phải đơn của tôi',
          ),
          isFalse,
        );

        expect(
          await AuthService.login(email: user.email, password: user.password),
          isTrue,
        );
        expect(
          await shop.addProductReview(
            orderId: orderId,
            productId: productId,
            rating: 4,
            productName: product.name,
            comment: 'Sản phẩm tốt',
          ),
          isTrue,
        );
        expect(
          await shop.addProductReview(
            orderId: orderId,
            productId: productId,
            rating: 5,
            productName: product.name,
            comment: 'Đánh giá trùng',
          ),
          isFalse,
        );

        expect(shop.reviews, hasLength(1));
        expect(shop.reviews.single.rating, 4);
        expect(shop.reviews.single.comment, 'Sản phẩm tốt');
        expect(
          shop.products
              .singleWhere((Product item) => item.id == productId)
              .rating,
          4,
        );
        expect(
          shop.products
              .singleWhere((Product item) => item.id == productId)
              .reviewCount,
          1,
        );

        expect(
          await AuthService.login(
            email: otherUser.email,
            password: otherUser.password,
          ),
          isTrue,
        );
        await shop.refreshData();
        expect(shop.reviews, isEmpty);

        expect(
          await AuthService.login(email: admin.email, password: admin.password),
          isTrue,
        );
        await shop.refreshData();
        expect(shop.reviews, hasLength(1));
      } finally {
        shop.dispose();
      }
    },
  );
}
