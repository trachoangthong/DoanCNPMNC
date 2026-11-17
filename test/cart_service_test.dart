import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CartService.initialize();
    await CartService.clearCart();
  });

  test('addProduct stores a product in the cart', () async {
    final product = Product(
      name: 'Test Product',
      image: 'test.png',
      price: 120000,
      category: 'Phones',
      description: 'A test product',
    );

    await CartService.addProduct(product);

    final cart = await CartService.getCart();
    expect(cart, hasLength(1));
    expect(cart.first.name, 'Test Product');
  });
}
