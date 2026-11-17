import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/database_helper.dart';
import 'package:flutter_application_1/screens/admin/admin_discount_coupon_page.dart';

Future<void> _pumpAfterDatabase(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
}

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

  testWidgets('canceling coupon creation returns to the coupon list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDiscountCouponPage()));
    await _pumpAfterDatabase(tester);
    expect(find.text('Chưa có mã giảm giá'), findsOneWidget);

    await tester.tap(find.byTooltip('Thêm mã giảm giá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'cancelled');
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Chưa có mã giảm giá'), findsOneWidget);
  });

  testWidgets('saving a coupon refreshes and shows it on the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDiscountCouponPage()));
    await _pumpAfterDatabase(tester);

    await tester.tap(find.byTooltip('Thêm mã giảm giá'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'summer20');
    await tester.enterText(find.byType(TextFormField).at(1), '20');
    await tester.tap(find.text('Lưu'));
    await _pumpAfterDatabase(tester);

    expect(find.byType(AlertDialog), findsNothing);
    final coupons = await tester.runAsync(
      DatabaseHelper.instance.getDiscountCoupons,
    );
    expect(coupons, hasLength(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SUMMER20'), findsOneWidget);
  });
}
