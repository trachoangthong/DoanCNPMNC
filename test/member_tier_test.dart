import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/member_tier.dart';
import 'package:flutter_application_1/models/order.dart';

void main() {
  test('member tiers follow the requested spending thresholds', () {
    expect(MemberTier.fromTotalSpent(0).name, 'Đồng');
    expect(MemberTier.fromTotalSpent(15000000).name, 'Đồng');
    expect(MemberTier.fromTotalSpent(15000001).name, 'Bạc');
    expect(MemberTier.fromTotalSpent(30000000).name, 'Bạc');
    expect(MemberTier.fromTotalSpent(30000001).name, 'Vàng');
    expect(MemberTier.fromTotalSpent(50000000).name, 'Vàng');
    expect(MemberTier.fromTotalSpent(50000001).name, 'Kim cương');
  });

  test('member tier reports remaining spend and progress to the next tier', () {
    final bronze = MemberTier.fromTotalSpent(5000000);
    expect(bronze.remainingToNextTier, 10000001);
    expect(bronze.progressToNextTier, closeTo(5000000 / 15000001, 0.0001));

    final diamond = MemberTier.fromTotalSpent(60000000);
    expect(diamond.remainingToNextTier, isNull);
    expect(diamond.progressToNextTier, 1);
  });

  test('only delivered orders contribute to member tier spending', () {
    final List<OrderModel> orders = <OrderModel>[
      _order(10000000, OrderStatus.delivered),
      _order(6000000, OrderStatus.delivered),
      _order(25000000, OrderStatus.pending),
      _order(30000000, OrderStatus.cancelled),
    ];

    final MemberTierSummary summary = MemberTierSummary.fromOrders(orders);

    expect(summary.tier.totalSpent, 16000000);
    expect(summary.tier.name, 'Bạc');
    expect(summary.completedOrderCount, 2);
  });
}

OrderModel _order(double total, OrderStatus status) {
  return OrderModel(date: DateTime(2026), total: total, status: status);
}
