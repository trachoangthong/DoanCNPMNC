import 'package:flutter_application_1/models/discount_coupon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('discount coupon serializes its fields and normalizes its code', () {
    final DiscountCoupon coupon = DiscountCoupon(
      id: 4,
      code: 'summer25',
      discountPercent: 25,
      expiresAt: DateTime(2026, 12, 31),
      isActive: false,
    );

    final Map<String, Object?> json = coupon.toJson();
    final DiscountCoupon restored = DiscountCoupon.fromJson(
      json.map((String key, Object? value) => MapEntry(key, value)),
    );

    expect(json['code'], 'SUMMER25');
    expect(restored.id, 4);
    expect(restored.discountPercent, 25);
    expect(restored.expiresAt, DateTime(2026, 12, 31));
    expect(restored.isActive, isFalse);
  });
}
