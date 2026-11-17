import 'product.dart';

class CartItem {
  final int? id;
  final Product product;
  int quantity;

  CartItem({
    this.id,
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': product.id,
      'quantity': quantity,
    };
  }
}
