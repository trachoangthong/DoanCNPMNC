import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/database_helper.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/screens/main_pages/favorites_page.dart';
import 'package:flutter_application_1/services/shop_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Favorite');
    await db.delete('Product');
    await db.delete('Category');
    await db.delete('Cart');
  });

  testWidgets('favorites page shows products saved in database when opened', (tester) async {
    final product = Product(
      name: 'Test favorite product',
      image: 'test.png',
      price: 120000,
      category: 'Phones',
      description: 'A test product',
    );

    final insertedId = await DatabaseHelper.instance.insertProduct(product);
    await DatabaseHelper.instance.insertFavorite(insertedId);

    final provider = ShopProvider();
    await provider.refreshData();
    await tester.pumpWidget(
      ChangeNotifierProvider<ShopProvider>.value(
        value: provider,
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test favorite product'), findsOneWidget);
  });
}
