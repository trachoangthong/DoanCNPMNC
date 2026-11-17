import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/order.dart';

void main() {
  test('order owner email is serialized and restored', () {
    final order = OrderModel(
      date: DateTime(2026, 11, 4),
      total: 100000,
      status: OrderStatus.pending,
      userEmail: 'user@example.com',
      paymentMethod: PaymentMethod.vnpay,
    );

    final restored = OrderModel.fromJson(order.toJson(), const []);

    expect(restored.userEmail, 'user@example.com');
    expect(restored.paymentMethod, PaymentMethod.vnpay);
    expect(restored.paymentMethod.label, 'Quét mã VNPay');
  });

  test('legacy order without payment method defaults to cash', () {
    final order = OrderModel.fromJson(<String, dynamic>{
      'date': DateTime(2026, 11, 4).toIso8601String(),
      'total': 100000,
      'status': 'pending',
    }, const []);

    expect(order.paymentMethod, PaymentMethod.cash);
  });

  test('order numbers start at one independently for each user', () {
    final Map<int, int> orderNumbers = calculateUserOrderNumbers(<OrderModel>[
      OrderModel(
        id: 3,
        date: DateTime(2026, 11, 16, 10),
        total: 300000,
        status: OrderStatus.pending,
        userEmail: 'user-b@example.com',
      ),
      OrderModel(
        id: 2,
        date: DateTime(2026, 11, 16, 9),
        total: 200000,
        status: OrderStatus.pending,
        userEmail: 'user-a@example.com',
      ),
      OrderModel(
        id: 1,
        date: DateTime(2026, 11, 16, 8),
        total: 100000,
        status: OrderStatus.pending,
        userEmail: 'USER-A@example.com',
      ),
    ]);

    expect(orderNumbers, <int, int>{1: 1, 2: 2, 3: 1});
  });
}
