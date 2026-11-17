import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/order.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/models/product_review.dart';
import 'package:flutter_application_1/screens/admin/admin_page.dart';
import 'package:flutter_application_1/screens/main_pages/product_detail_page.dart';
import 'package:flutter_application_1/screens/main_pages/order_history_page.dart';
import 'package:flutter_application_1/services/shop_provider.dart';

class _TestShopProvider extends ShopProvider {
  final List<Category> _categories = <Category>[
    Category(
      name: 'Điện thoại',
      image: 'category.png',
      description: 'Điện thoại',
    ),
  ];
  final List<Product> _products = <Product>[];
  final List<OrderModel> _orders = <OrderModel>[];
  final List<ProductReview> _reviews = <ProductReview>[];

  @override
  Future<void> refreshData() async {}

  @override
  List<Category> get categories => _categories;

  @override
  List<Product> get products => _products;

  @override
  List<OrderModel> get orders => _orders;

  @override
  List<ProductReview> get reviews => _reviews;

  @override
  Future<int> addProduct(Product product) async {
    _products.add(product.copyWith(id: 1));
    notifyListeners();
    return 1;
  }

  @override
  Future<bool> addProductReview({
    required int orderId,
    required int productId,
    required int rating,
    required String productName,
    required String comment,
  }) async {
    _reviews.add(
      ProductReview(
        orderId: orderId,
        productId: productId,
        productName: productName,
        userEmail: 'reviewer@example.com',
        userName: 'Người đánh giá',
        rating: rating,
        comment: comment,
        createdAt: DateTime(2026, 11, 16),
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<List<ProductReview>> getProductReviewsByProduct(int productId) async {
    return _reviews
        .where((ProductReview review) => review.productId == productId)
        .toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryName) async {
    return <Product>[];
  }
}

void main() {
  testWidgets('saving a product returns to the admin product list', (
    WidgetTester tester,
  ) async {
    final _TestShopProvider shop = _TestShopProvider();
    addTearDown(shop.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: shop,
        child: const MaterialApp(home: AdminPage()),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Điện thoại mới');
    await tester.enterText(find.byType(TextFormField).at(1), '12500000');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'https://example.com/product.jpg',
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Điện thoại mới'), findsOneWidget);
    expect(find.text('Thêm sản phẩm thành công'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin order details show customer and purchased product', (
    WidgetTester tester,
  ) async {
    final _TestShopProvider shop = _TestShopProvider();
    shop._orders.add(
      OrderModel(
        id: 12,
        date: DateTime(2026, 11, 16),
        total: 25000000,
        status: OrderStatus.pending,
        customerName: 'Nguyễn An',
        customerPhone: '0901234567',
        address: '12 Nguyễn Huệ, TP. Hồ Chí Minh',
        userEmail: 'an@example.com',
        items: <OrderItem>[
          OrderItem(
            product: const Product(
              id: 7,
              name: 'Điện thoại mẫu',
              image: 'https://example.com/product.jpg',
              price: 25000000,
              category: 'Điện thoại',
              description: 'Sản phẩm kiểm tra',
            ),
            quantity: 1,
            price: 25000000,
          ),
        ],
      ),
    );
    addTearDown(shop.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: shop,
        child: const MaterialApp(home: AdminPage()),
      ),
    );
    await tester.ensureVisible(find.text('Đơn hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đơn hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đơn hàng #1'));
    await tester.pumpAndSettle();

    expect(find.text('Họ tên: Nguyễn An'), findsOneWidget);
    expect(find.text('Số điện thoại: 0901234567'), findsOneWidget);
    expect(
      find.text('Địa chỉ: 12 Nguyễn Huệ, TP. Hồ Chí Minh'),
      findsOneWidget,
    );
    expect(find.text('Email: an@example.com'), findsOneWidget);
    expect(find.text('Điện thoại mẫu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a users first order is numbered one even with a global id of 3',
    (WidgetTester tester) async {
      final _TestShopProvider shop = _TestShopProvider();
      shop._orders.add(
        OrderModel(
          id: 3,
          date: DateTime(2026, 11, 16),
          total: 25000000,
          status: OrderStatus.pending,
          userEmail: 'user-b@example.com',
        ),
      );
      addTearDown(shop.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<ShopProvider>.value(
          value: shop,
          child: const MaterialApp(home: OrderHistoryPage()),
        ),
      );

      expect(find.text('Đơn hàng #1'), findsOneWidget);
      expect(find.text('Đơn hàng #3'), findsNothing);
    },
  );

  testWidgets('admin can read submitted product reviews', (
    WidgetTester tester,
  ) async {
    final _TestShopProvider shop = _TestShopProvider();
    shop._reviews.add(
      ProductReview(
        orderId: 3,
        productId: 8,
        productName: 'Điện thoại được đánh giá',
        userEmail: 'reviewer@example.com',
        userName: 'Người đánh giá',
        rating: 4,
        comment: 'Sản phẩm tốt',
        createdAt: DateTime(2026, 11, 16),
      ),
    );
    addTearDown(shop.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: shop,
        child: const MaterialApp(home: AdminPage()),
      ),
    );
    await tester.ensureVisible(find.text('Đánh giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh giá'));
    await tester.pumpAndSettle();

    expect(find.text('Điện thoại được đánh giá'), findsOneWidget);
    expect(find.text('Người đánh giá (reviewer@example.com)'), findsOneWidget);
    expect(find.text('Sản phẩm tốt'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delivered order lets the user choose a star rating', (
    WidgetTester tester,
  ) async {
    final _TestShopProvider shop = _TestShopProvider();
    shop._orders.add(
      OrderModel(
        id: 3,
        date: DateTime(2026, 11, 16),
        total: 25000000,
        status: OrderStatus.delivered,
        userEmail: 'reviewer@example.com',
        items: <OrderItem>[
          OrderItem(
            product: const Product(
              id: 8,
              name: 'Điện thoại được đánh giá',
              image: 'iphone.png',
              price: 25000000,
              category: 'Điện thoại',
              description: 'Sản phẩm kiểm tra',
            ),
            quantity: 1,
            price: 25000000,
          ),
        ],
      ),
    );
    addTearDown(shop.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: shop,
        child: const MaterialApp(home: OrderHistoryPage()),
      ),
    );
    await tester.tap(find.text('Đơn hàng #1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh giá sản phẩm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2 sao'));
    await tester.enterText(find.byType(TextField), 'Chụp ảnh rõ nét');
    await tester.tap(find.text('Gửi đánh giá'));
    await tester.pumpAndSettle();

    expect(shop.reviews.single.rating, 2);
    expect(shop.reviews.single.comment, 'Chụp ảnh rõ nét');
    expect(find.text('Cảm ơn bạn đã đánh giá'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product details show reviews for that product only', (
    WidgetTester tester,
  ) async {
    final _TestShopProvider shop = _TestShopProvider();
    shop._reviews.add(
      ProductReview(
        orderId: 3,
        productId: 8,
        productName: 'Điện thoại được đánh giá',
        userEmail: 'private@example.com',
        userName: 'Người đánh giá',
        rating: 4,
        comment: 'Chụp ảnh rõ nét',
        createdAt: DateTime(2026, 11, 16),
      ),
    );
    shop._reviews.add(
      ProductReview(
        orderId: 4,
        productId: 9,
        productName: 'Sản phẩm khác',
        userEmail: 'other@example.com',
        userName: 'Người khác',
        rating: 1,
        comment: 'Không hiển thị ở sản phẩm này',
        createdAt: DateTime(2026, 11, 15),
      ),
    );
    addTearDown(shop.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: shop,
        child: const MaterialApp(
          home: ProductDetailPage(
            product: Product(
              id: 8,
              name: 'Điện thoại được đánh giá',
              image: 'iphone.png',
              price: 25000000,
              category: 'Điện thoại',
              description: 'Sản phẩm kiểm tra',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đánh giá sản phẩm (1)'), findsOneWidget);
    expect(find.text('Người đánh giá'), findsOneWidget);
    expect(find.text('Chụp ảnh rõ nét'), findsOneWidget);
    expect(find.text('private@example.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
