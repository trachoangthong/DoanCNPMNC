import 'order.dart';

class MemberTier {
  const MemberTier._(this.totalSpent);

  static const int bronzeMaximum = 15000000;
  static const int silverMaximum = 30000000;
  static const int goldMaximum = 50000000;

  final int totalSpent;

  factory MemberTier.fromTotalSpent(int totalSpent) {
    return MemberTier._(totalSpent < 0 ? 0 : totalSpent);
  }

  String get name {
    if (totalSpent <= bronzeMaximum) {
      return 'Đồng';
    }
    if (totalSpent <= silverMaximum) {
      return 'Bạc';
    }
    if (totalSpent <= goldMaximum) {
      return 'Vàng';
    }
    return 'Kim cương';
  }

  int? get nextTierThreshold {
    if (totalSpent <= bronzeMaximum) {
      return bronzeMaximum + 1;
    }
    if (totalSpent <= silverMaximum) {
      return silverMaximum + 1;
    }
    if (totalSpent <= goldMaximum) {
      return goldMaximum + 1;
    }
    return null;
  }

  int? get remainingToNextTier {
    final int? threshold = nextTierThreshold;
    return threshold == null ? null : threshold - totalSpent;
  }

  double get progressToNextTier {
    final int? threshold = nextTierThreshold;
    if (threshold == null) {
      return 1;
    }

    final int lowerBound = totalSpent <= bronzeMaximum
        ? 0
        : totalSpent <= silverMaximum
        ? bronzeMaximum
        : silverMaximum;
    return ((totalSpent - lowerBound) / (threshold - lowerBound)).clamp(
      0.0,
      1.0,
    );
  }
}

class MemberTierSummary {
  const MemberTierSummary({
    required this.tier,
    required this.completedOrderCount,
  });

  final MemberTier tier;
  final int completedOrderCount;

  factory MemberTierSummary.fromOrders(List<OrderModel> orders) {
    final List<OrderModel> completedOrders = orders
        .where((OrderModel order) => order.status == OrderStatus.delivered)
        .toList();
    final int totalSpent = completedOrders.fold<int>(
      0,
      (int total, OrderModel order) => total + order.total.round(),
    );
    return MemberTierSummary(
      tier: MemberTier.fromTotalSpent(totalSpent),
      completedOrderCount: completedOrders.length,
    );
  }
}
