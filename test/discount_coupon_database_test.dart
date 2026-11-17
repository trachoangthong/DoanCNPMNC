import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/database_helper.dart';
import 'package:flutter_application_1/models/discount_coupon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    final Database db = await DatabaseHelper.instance.database;
    await db.delete('DiscountCoupons');
  });

  test(
    'discount coupons can be created, updated, listed, and deleted',
    () async {
      final DatabaseHelper database = DatabaseHelper.instance;
      final DiscountCoupon coupon = DiscountCoupon(
        code: 'winter20',
        discountPercent: 20,
        expiresAt: DateTime(2026, 12, 31),
      );

      final int id = await database.insertDiscountCoupon(coupon);
      final List<DiscountCoupon> inserted = await database.getDiscountCoupons();
      expect(inserted, hasLength(1));
      expect(inserted.single.id, id);
      expect(inserted.single.code, 'WINTER20');

      await database.updateDiscountCoupon(
        DiscountCoupon(
          id: id,
          code: 'winter30',
          discountPercent: 30,
          expiresAt: DateTime(2027, 1, 31),
          isActive: false,
        ),
      );
      final DiscountCoupon updated =
          (await database.getDiscountCoupons()).single;
      expect(updated.code, 'WINTER30');
      expect(updated.discountPercent, 30);
      expect(updated.isActive, isFalse);

      await database.deleteDiscountCoupon(id);
      expect(await database.getDiscountCoupons(), isEmpty);
    },
  );

  test('discount coupon codes are unique regardless of letter case', () async {
    final DatabaseHelper database = DatabaseHelper.instance;
    final DateTime expiry = DateTime(2026, 12, 31);
    await database.insertDiscountCoupon(
      DiscountCoupon(code: 'SAVE10', discountPercent: 10, expiresAt: expiry),
    );

    expect(
      () => database.insertDiscountCoupon(
        DiscountCoupon(code: 'save10', discountPercent: 15, expiresAt: expiry),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });
}
