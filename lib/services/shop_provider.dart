import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/user_model.dart';
import '../models/product_review.dart';
import 'auth_service.dart';

class ShopProvider with ChangeNotifier {
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _favorites = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<OrderModel> _orders = [];
  List<ProductReview> _reviews = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  int _refreshRequestId = 0;
  String? _ordersScope;
  String? _reviewsScope;
  bool _isDisposed = false;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Product> get favorites => _favorites;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<OrderModel> get orders => _orders;
  List<ProductReview> get reviews => _reviews;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  double get cartTotal {
    double total = 0;
    for (var item in _cartItems) {
      final price = (item['price'] as num).toDouble();
      final qty = item['quantity'] as int;
      total += price * qty;
    }
    return total;
  }

  int get cartCount {
    int count = 0;
    for (var item in _cartItems) {
      count += item['quantity'] as int;
    }
    return count;
  }

  ShopProvider() {
    refreshData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListenersIfAlive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    if (_isDisposed) return;

    final int refreshRequestId = ++_refreshRequestId;
    _isLoading = true;
    _notifyListenersIfAlive();

    try {
      final categories = await DatabaseHelper.instance.getCategories();
      final products = await DatabaseHelper.instance.getProducts();
      final favorites = await DatabaseHelper.instance.getFavorites();
      final cartItems = await DatabaseHelper.instance.getCartItems();
      final user = await AuthService.currentUser();
      final bool isAdmin = user?.role.toLowerCase() == 'admin';
      final String? ordersScope = user == null
          ? null
          : isAdmin
          ? 'admin'
          : 'user:${user.email.trim().toLowerCase()}';
      final orders = user == null
          ? <OrderModel>[]
          : isAdmin
          ? await DatabaseHelper.instance.getOrders()
          : await DatabaseHelper.instance.getOrdersByUser(user.email);
      final reviews = user == null
          ? <ProductReview>[]
          : isAdmin
          ? await DatabaseHelper.instance.getProductReviews()
          : await DatabaseHelper.instance.getProductReviewsByUser(user.email);
      final users = await AuthService.getAllUsers();

      if (!_isDisposed && refreshRequestId == _refreshRequestId) {
        _categories = categories;
        _products = products;
        _favorites = favorites;
        _cartItems = cartItems;
        if (_ordersScope != ordersScope) {
          _orders = [];
        }
        if (_reviewsScope != ordersScope) {
          _reviews = [];
        }
        _ordersScope = ordersScope;
        _reviewsScope = ordersScope;
        _orders = orders;
        _reviews = reviews;
        _users = users;
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }

    if (!_isDisposed && refreshRequestId == _refreshRequestId) {
      _isLoading = false;
      _notifyListenersIfAlive();
    }
  }

  Future<bool> placeOrder({
    String? name,
    String? phone,
    String? address,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    double discountAmount = 0,
  }) async {
    if (_cartItems.isEmpty ||
        !discountAmount.isFinite ||
        discountAmount < 0 ||
        discountAmount > cartTotal) {
      return false;
    }

    final user = await AuthService.currentUser();

    try {
      final order = OrderModel(
        date: DateTime.now(),
        total: cartTotal - discountAmount,
        status: OrderStatus.pending,
        customerName: name ?? user?.fullName ?? 'Khách lẻ',
        customerPhone: phone ?? user?.phone ?? '',
        address: address ?? user?.city ?? 'Tại cửa hàng',
        userEmail: user?.email.trim().toLowerCase(),
        paymentMethod: paymentMethod,
        items: _cartItems.map((item) {
          return OrderItem(
            product: Product.fromJson(item),
            quantity: item['quantity'] as int,
            price: (item['price'] as num).toDouble(),
          );
        }).toList(),
      );

      await DatabaseHelper.instance.insertOrder(order);
      await clearCart();
      await refreshData();
      return true;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return false;
    }
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    await DatabaseHelper.instance.updateOrderStatus(orderId, status);
    await refreshData();
  }

  Future<bool> addProductReview({
    required int orderId,
    required int productId,
    required int rating,
    required String productName,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      return false;
    }

    final user = await AuthService.currentUser();
    if (user == null || user.role.toLowerCase() == 'admin') {
      return false;
    }

    final bool saved = await DatabaseHelper.instance.insertProductReview(
      ProductReview(
        orderId: orderId,
        productId: productId,
        productName: productName,
        userEmail: user.email,
        userName: user.fullName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      ),
    );
    if (saved) {
      await refreshData();
    }
    return saved;
  }

  Future<List<ProductReview>> getProductReviewsByProduct(int productId) {
    return DatabaseHelper.instance.getProductReviewsByProduct(productId);
  }

  Future<int> addProduct(Product product) async {
    final newId = await DatabaseHelper.instance.insertProduct(product);
    await refreshData();
    return newId;
  }

  Future<bool> updateProduct(Product product) async {
    if (product.id == null) {
      return false;
    }
    final rows = await DatabaseHelper.instance.updateProduct(product);
    if (rows > 0) {
      await refreshData();
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(int productId) async {
    final rows = await DatabaseHelper.instance.deleteProduct(productId);
    if (rows > 0) {
      await refreshData();
      return true;
    }
    return false;
  }

  Future<void> addCategory(Category category) async {
    await DatabaseHelper.instance.insertCategory(category);
    await refreshData();
  }

  Future<void> updateCategory(Category category) async {
    await DatabaseHelper.instance.updateCategory(category);
    await refreshData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await refreshData();
  }

  Future<void> updateUser(UserModel user) async {
    await AuthService.updateUser(user);
    await refreshData();
  }

  Future<void> deleteUser(String email) async {
    await AuthService.deleteUser(email);
    await refreshData();
  }

  Future<void> toggleFavorite(Product product) async {
    if (product.id == null) {
      return;
    }
    final isFav = await DatabaseHelper.instance.isFavorite(product.id!);
    if (isFav) {
      await DatabaseHelper.instance.deleteFavorite(product.id!);
    } else {
      await DatabaseHelper.instance.insertFavorite(product.id!);
    }
    _favorites = await DatabaseHelper.instance.getFavorites();
    _notifyListenersIfAlive();
  }

  bool isProductFavorite(int productId) {
    return _favorites.any((p) => p.id == productId);
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (product.id == null) {
      return;
    }
    await DatabaseHelper.instance.insertCart(product.id!, quantity);
    _cartItems = await DatabaseHelper.instance.getCartItems();
    _notifyListenersIfAlive();
  }

  Future<void> updateCartQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await DatabaseHelper.instance.deleteCartItem(productId);
    } else {
      await DatabaseHelper.instance.updateCartQuantity(productId, quantity);
    }
    _cartItems = await DatabaseHelper.instance.getCartItems();
    _notifyListenersIfAlive();
  }

  Future<void> removeFromCart(int productId) async {
    await DatabaseHelper.instance.deleteCartItem(productId);
    _cartItems = await DatabaseHelper.instance.getCartItems();
    _notifyListenersIfAlive();
  }

  Future<void> clearCart() async {
    await DatabaseHelper.instance.clearCart();
    _cartItems = [];
    _notifyListenersIfAlive();
  }

  Future<List<Product>> getFilteredProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? query,
  }) async {
    return await DatabaseHelper.instance.getFilteredProducts(
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      query: query,
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    return await DatabaseHelper.instance.searchProducts(query);
  }

  Future<List<Product>> getProductsByCategory(String categoryName) async {
    return await DatabaseHelper.instance.getProductsByCategory(categoryName);
  }
}
