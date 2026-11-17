import 'product.dart';

enum OrderStatus { pending, confirmed, shipping, delivered, cancelled }

enum PaymentMethod { cash, bankTransfer, vnpay }

extension PaymentMethodDisplay on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.bankTransfer:
        return 'Thanh toán qua ngân hàng';
      case PaymentMethod.vnpay:
        return 'Quét mã VNPay';
    }
  }
}

class OrderItem {
  final int? id;
  final int? orderId;
  final Product product;
  final int quantity;
  final double price;

  OrderItem({
    this.id,
    this.orderId,
    required this.product,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': product.id,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  final int? id;
  final DateTime date;
  final double total;
  final OrderStatus status;
  final List<OrderItem> items;
  final String customerName;
  final String customerPhone;
  final String address;
  final String? userEmail;
  final PaymentMethod paymentMethod;

  OrderModel({
    this.id,
    required this.date,
    required this.total,
    required this.status,
    this.items = const [],
    this.customerName = '',
    this.customerPhone = '',
    this.address = '',
    this.userEmail,
    this.paymentMethod = PaymentMethod.cash,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total': total,
      'status': status.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'userEmail': userEmail,
      'paymentMethod': paymentMethod.name,
    };
  }

  factory OrderModel.fromJson(
    Map<String, dynamic> json,
    List<OrderItem> items,
  ) {
    return OrderModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: items,
      customerName: json['customerName'] ?? 'Khách lẻ',
      customerPhone: json['customerPhone'] ?? '',
      address: json['address'] ?? '',
      userEmail: json['userEmail'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (PaymentMethod method) => method.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
    );
  }
}

Map<int, int> calculateUserOrderNumbers(Iterable<OrderModel> orders) {
  final List<OrderModel> chronologicalOrders = orders.toList()
    ..sort((OrderModel first, OrderModel second) {
      final int dateComparison = first.date.compareTo(second.date);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return (first.id ?? 0).compareTo(second.id ?? 0);
    });

  final Map<String, int> nextNumberByUser = <String, int>{};
  final Map<int, int> orderNumbers = <int, int>{};
  for (final OrderModel order in chronologicalOrders) {
    final int? orderId = order.id;
    if (orderId == null) {
      continue;
    }

    final String? email = order.userEmail?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      orderNumbers[orderId] = orderId;
      continue;
    }

    final int number = (nextNumberByUser[email] ?? 0) + 1;
    nextNumberByUser[email] = number;
    orderNumbers[orderId] = number;
  }

  return orderNumbers;
}
