import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/discount_coupon.dart';
import '../models/product_review.dart';
import '../models/app_notification.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('cellphones_final.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Orders ADD COLUMN userEmail TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE Orders ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT 'cash'",
          );
        }
        if (oldVersion < 4) {
          await _createDiscountCouponsTable(db);
        }
        if (oldVersion < 5) {
          await _createProductReviewsTable(db);
        }
        if (oldVersion < 6) {
          await _createNotificationsTables(db);
        }
      },
      onOpen: (Database db) async {
        await _createDiscountCouponsTable(db);
        await _createProductReviewsTable(db);
        await _createNotificationsTables(db);
      },
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Product (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        discount REAL DEFAULT 0,
        specifications TEXT,
        availableQuantity INTEGER DEFAULT 10,
        rating REAL DEFAULT 4.5,
        reviewCount INTEGER DEFAULT 0,
        images TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Favorite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL UNIQUE,
        FOREIGN KEY (productId) REFERENCES Product (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL UNIQUE,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (productId) REFERENCES Product (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        customerName TEXT,
        customerPhone TEXT,
        address TEXT,
        userEmail TEXT,
        paymentMethod TEXT NOT NULL DEFAULT 'cash'
      )
    ''');

    await db.execute('''
      CREATE TABLE OrderItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES Orders (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES Product (id) ON DELETE CASCADE
      )
    ''');

    await _createProductReviewsTable(db);
    await _createDiscountCouponsTable(db);
    await _createNotificationsTables(db);

    await seedInitialData(db);
  }

  Future<void> _createNotificationsTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        senderEmail TEXT NOT NULL,
        targetEmail TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS NotificationRecipients (
        notificationId INTEGER NOT NULL,
        userEmail TEXT NOT NULL,
        PRIMARY KEY (notificationId, userEmail),
        FOREIGN KEY (notificationId)
          REFERENCES Notifications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS NotificationReads (
        notificationId INTEGER NOT NULL,
        userEmail TEXT NOT NULL,
        readAt TEXT NOT NULL,
        PRIMARY KEY (notificationId, userEmail),
        FOREIGN KEY (notificationId)
          REFERENCES Notifications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notifications_target_created
      ON Notifications(targetEmail, createdAt)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_recipients_user
      ON NotificationRecipients(userEmail)
    ''');
  }

  Future<void> _createDiscountCouponsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS DiscountCoupons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL COLLATE NOCASE UNIQUE,
        discountPercent REAL NOT NULL,
        expiresAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _createProductReviewsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ProductReviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        userEmail TEXT NOT NULL,
        userName TEXT NOT NULL,
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        UNIQUE(orderId, productId),
        FOREIGN KEY (orderId) REFERENCES Orders (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_product_reviews_user
      ON ProductReviews(userEmail)
    ''');
  }

  Future<void> seedInitialData(Database db) async {
    final List<Map<String, Object?>> catCheck = await db.query(
      'Category',
      limit: 1,
    );
    if (catCheck.isEmpty) {
      final List<Map<String, Object?>> categories = <Map<String, Object?>>[
        {
          'name': 'Điện thoại Apple',
          'image': 'Apple.png',
          'description': 'Điện thoại Apple mới nhất',
        },
        {
          'name': 'Điện thoại Samsung',
          'image': 'Samsung.png',
          'description': 'Điện thoại Samsung mới nhất',
        },
        {
          'name': 'Điện thoại Xiaomi',
          'image': 'xiaomi.png',
          'description': 'Điện thoại Xiaomi mới nhất',
        },
        {
          'name': 'Phụ kiện',
          'image': 'logophukien.png',
          'description': 'Phụ kiện cho điện thoại',
        },
        
      ];
      for (final Map<String, Object?> cat in categories) {
        await db.insert('Category', cat);
      }
    }

    final List<Map<String, Object?>> prodCheck = await db.query(
      'Product',
      limit: 1,
    );
    if (prodCheck.isEmpty) {
      final List<Map<String, Object?>> products = <Map<String, Object?>>[
        {
          'name': 'iPhone 18 Pro Max',
          'image': 'iphone18promax.png',
          'price': 41900000.0,
          'category': 'Điện thoại Apple',
          'description': 'Chip A20 Pro, Camera 48MP.',
          'discount': 5.0,
          'availableQuantity': 10,
        },
        {
          'name': 'iPhone 17 Pro Max',
          'image': 'iphone17.png',
          'price': 34990000.0,
          'category': 'Điện thoại Apple',
          'description': 'Chip A17 Pro, Camera 48MP.',
          'discount': 5.0,
          'availableQuantity': 10,
        },
        {
          'name': 'iPhone 16 Pro Max',
          'image': 'iphone.png',
          'price': 25000000.0,
          'category': 'Điện thoại Apple',
          'description': 'Chip A16 Bionic, Camera 48MP.',
          'discount': 5.0,
          'availableQuantity': 10,
        },
        {
          'name': 'Iphone 15 Pro Max',
          'image': 'iphone15.png',
          'price': 20000000.0,
          'category': 'Điện thoại Apple',
          'description': 'Chip A15 Bionic, Camera 48MP.',
          'discount': 10.0,
          'availableQuantity': 15,
        },

        {
          'name': 'Samsung Galaxy S24 Ultra',
          'image': 'samsung_s24_ultra.png',
          'price': 30990000.0,
          'category': 'Điện thoại Samsung',
          'description': 'Camera 200MP, Pin 5000mAh.',
          'discount': 10.0,
          'availableQuantity': 15,
        },
        {
          'name': 'Xiaomi 18 Pro',
          'image': 'xiaomi_18_pro.png',
          'price': 19990000.0,
          'category': 'Điện thoại Xiaomi',
          'description': 'Màn hình AMOLED, Sạc nhanh 120W.',
          'discount': 7.5,
          'availableQuantity': 20,
        },
        {
          'name': 'Ốp lưng iPhone 18 Pro Max Apple Techwoven With Magsafe',
          'image': 'phukien.png',
          'price': 1649000.0,
          'category': 'Phụ kiện',
          'description': 'Ốp lưng chính hãng Apple cho iPhone 18 Pro Max, chất liệu Techwoven, hỗ trợ Magsafe.',
          'discount': 5.0,
          'availableQuantity': 25,
        },
        
      ];
      for (final Map<String, Object?> prod in products) {
        await db.insert('Product', prod);
      }
    }
  }

  Future<List<Category>> getCategories() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.query('Category');
    return result.map((Map<String, Object?> json) {
      return Category.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<List<Product>> getProducts() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.query('Product');
    return result.map((Map<String, Object?> json) {
      return Product.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<int> insertProduct(Product product) async {
    final Database db = await instance.database;
    return await db.insert('Product', product.toJson());
  }

  Future<int> updateProduct(Product product) async {
    if (product.id == null) {
      return 0;
    }
    final Database db = await instance.database;
    return await db.update(
      'Product',
      product.toJson(),
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final Database db = await instance.database;
    return await db.delete(
      'Product',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<DiscountCoupon>> getDiscountCoupons() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.query(
      'DiscountCoupons',
      orderBy: 'code COLLATE NOCASE',
    );
    return result.map((Map<String, Object?> json) {
      return DiscountCoupon.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<int> insertDiscountCoupon(DiscountCoupon coupon) async {
    final Database db = await instance.database;
    return db.insert('DiscountCoupons', coupon.toJson());
  }

  Future<int> updateDiscountCoupon(DiscountCoupon coupon) async {
    if (coupon.id == null) {
      return 0;
    }
    final Database db = await instance.database;
    return db.update(
      'DiscountCoupons',
      coupon.toJson(),
      where: 'id = ?',
      whereArgs: <Object?>[coupon.id],
    );
  }

  Future<int> deleteDiscountCoupon(int id) async {
    final Database db = await instance.database;
    return db.delete(
      'DiscountCoupons',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> insertCategory(Category category) async {
    final Database db = await instance.database;
    return await db.insert('Category', category.toJson());
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      return 0;
    }
    final Database db = await instance.database;
    return await db.update(
      'Category',
      category.toJson(),
      where: 'id = ?',
      whereArgs: <Object?>[category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final Database db = await instance.database;
    return await db.delete(
      'Category',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Product>> getFilteredProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? query,
  }) async {
    final Database db = await instance.database;
    String whereClause = '';
    final List<Object?> whereArgs = <Object?>[];

    if (category != null && category.isNotEmpty) {
      whereClause += 'category = ?';
      whereArgs.add(category);
    }
    if (minPrice != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'price >= ?';
      whereArgs.add(minPrice);
    }
    if (maxPrice != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'price <= ?';
      whereArgs.add(maxPrice);
    }
    if (query != null && query.trim().isNotEmpty) {
      final normalizedQuery = query.trim().toLowerCase();
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause +=
          '(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(category) LIKE ?)';
      whereArgs
        ..add('%$normalizedQuery%')
        ..add('%$normalizedQuery%')
        ..add('%$normalizedQuery%');
    }

    final List<Map<String, Object?>> result = await db.query(
      'Product',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    return result.map((Map<String, Object?> json) {
      return Product.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<int> insertOrder(OrderModel order) async {
    final Database db = await instance.database;
    return await db.transaction((Transaction txn) async {
      final int orderId = await txn.insert('Orders', order.toJson());
      for (final OrderItem item in order.items) {
        await txn.insert('OrderItems', <String, Object?>{
          'orderId': orderId,
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.price,
        });
        await txn.execute(
          'UPDATE Product SET availableQuantity = availableQuantity - ? WHERE id = ?',
          <Object?>[item.quantity, item.product.id],
        );
      }
      return orderId;
    });
  }

  Future<List<OrderModel>> getOrders() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> orderMaps = await db.query(
      'Orders',
      orderBy: 'date DESC, id DESC',
    );
    return _loadOrders(orderMaps);
  }

  Future<List<OrderModel>> getOrdersByUser(String userEmail) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> orderMaps = await db.query(
      'Orders',
      where: 'userEmail = ?',
      whereArgs: <Object?>[userEmail.trim().toLowerCase()],
      orderBy: 'date DESC, id DESC',
    );
    return _loadOrders(orderMaps);
  }

  Future<List<OrderModel>> _loadOrders(
    List<Map<String, Object?>> orderMaps,
  ) async {
    final List<OrderModel> orders = <OrderModel>[];
    for (final Map<String, Object?> map in orderMaps) {
      final int? id = map['id'] as int?;
      if (id != null) {
        final List<OrderItem> items = await getOrderItems(id);
        orders.add(
          OrderModel.fromJson(
            map.map(
              (String key, Object? value) =>
                  MapEntry<String, dynamic>(key, value),
            ),
            items,
          ),
        );
      }
    }
    return orders;
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.rawQuery(
      '''
      SELECT oi.id, oi.orderId, oi.quantity, oi.price,
             p.id as pid, p.name, p.image, p.category, p.description, p.price as p_price,
             p.discount, p.specifications, p.availableQuantity, p.rating, p.reviewCount, p.images
      FROM OrderItems oi 
      INNER JOIN Product p ON oi.productId = p.id 
      WHERE oi.orderId = ?
    ''',
      <Object?>[orderId],
    );

    return result.map((Map<String, Object?> json) {
      final Product product = Product(
        id: json['pid'] as int?,
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: (json['p_price'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        specifications: json['specifications'] as String? ?? '',
        availableQuantity: json['availableQuantity'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        images:
            (json['images'] as String?)
                ?.split(',')
                .where((String s) => s.isNotEmpty)
                .toList() ??
            <String>[],
      );
      return OrderItem(
        id: json['id'] as int?,
        orderId: json['orderId'] as int?,
        product: product,
        quantity: json['quantity'] as int? ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<List<ProductReview>> getProductReviews() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ProductReviews',
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(ProductReview.fromJson).toList();
  }

  Future<List<ProductReview>> getProductReviewsByUser(String userEmail) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ProductReviews',
      where: 'userEmail = ?',
      whereArgs: <Object?>[userEmail.trim().toLowerCase()],
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(ProductReview.fromJson).toList();
  }

  Future<List<ProductReview>> getProductReviewsByProduct(int productId) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      'ProductReviews',
      columns: <String>[
        'id',
        'orderId',
        'productId',
        'productName',
        'userName',
        'rating',
        'comment',
        'createdAt',
      ],
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(ProductReview.fromJson).toList();
  }

  Future<bool> insertProductReview(ProductReview review) async {
    if (review.rating < 1 || review.rating > 5) {
      return false;
    }

    final Database db = await instance.database;
    return db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> orders = await txn.query(
        'Orders',
        columns: <String>['status'],
        where: 'id = ? AND LOWER(TRIM(userEmail)) = ?',
        whereArgs: <Object?>[
          review.orderId,
          review.userEmail.trim().toLowerCase(),
        ],
      );
      if (orders.isEmpty ||
          orders.first['status'] != OrderStatus.delivered.name) {
        return false;
      }

      final List<Map<String, Object?>> purchasedItems = await txn.query(
        'OrderItems',
        columns: <String>['id'],
        where: 'orderId = ? AND productId = ?',
        whereArgs: <Object?>[review.orderId, review.productId],
        limit: 1,
      );
      if (purchasedItems.isEmpty) {
        return false;
      }

      final List<Map<String, Object?>> products = await txn.query(
        'Product',
        columns: <String>['name'],
        where: 'id = ?',
        whereArgs: <Object?>[review.productId],
        limit: 1,
      );
      if (products.isEmpty) {
        return false;
      }

      final List<Map<String, Object?>> existingReviews = await txn.query(
        'ProductReviews',
        columns: <String>['id'],
        where: 'orderId = ? AND productId = ?',
        whereArgs: <Object?>[review.orderId, review.productId],
        limit: 1,
      );
      if (existingReviews.isNotEmpty) {
        return false;
      }

      await txn.insert('ProductReviews', <String, Object?>{
        'orderId': review.orderId,
        'productId': review.productId,
        'productName': products.first['name'],
        'userEmail': review.userEmail.trim().toLowerCase(),
        'userName': review.userName.trim(),
        'rating': review.rating,
        'comment': review.comment.trim(),
        'createdAt': review.createdAt.toIso8601String(),
      });

      final List<Map<String, Object?>> aggregate = await txn.rawQuery(
        'SELECT AVG(rating) AS averageRating, COUNT(*) AS reviewCount '
        'FROM ProductReviews WHERE productId = ?',
        <Object?>[review.productId],
      );
      await txn.update(
        'Product',
        <String, Object?>{
          'rating': (aggregate.first['averageRating'] as num).toDouble(),
          'reviewCount': aggregate.first['reviewCount'] as int,
        },
        where: 'id = ?',
        whereArgs: <Object?>[review.productId],
      );
      return true;
    });
  }

  Future<int> updateOrderStatus(int orderId, OrderStatus status) async {
    final Database db = await instance.database;
    return await db.update(
      'Orders',
      <String, Object?>{'status': status.name},
      where: 'id = ?',
      whereArgs: <Object?>[orderId],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final Database db = await instance.database;
    await seedInitialData(db);

    final normalizedQuery = query.trim().toLowerCase();
    final List<Map<String, Object?>> result = await db.query(
      'Product',
      where:
          '(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(category) LIKE ?)',
      whereArgs: <Object?>[
        '%$normalizedQuery%',
        '%$normalizedQuery%',
        '%$normalizedQuery%',
      ],
    );
    return result.map((Map<String, Object?> json) {
      return Product.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.query(
      'Product',
      where: 'category = ?',
      whereArgs: <Object?>[category],
    );
    return result.map((Map<String, Object?> json) {
      return Product.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<int> insertFavorite(int productId) async {
    final Database db = await instance.database;
    return await db.insert('Favorite', <String, Object?>{
      'productId': productId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> deleteFavorite(int productId) async {
    final Database db = await instance.database;
    return await db.delete(
      'Favorite',
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
    );
  }

  Future<List<Product>> getFavorites() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.rawQuery(
      'SELECT Product.* FROM Product INNER JOIN Favorite ON Product.id = Favorite.productId',
    );
    return result.map((Map<String, Object?> json) {
      return Product.fromJson(
        json.map(
          (String key, Object? value) => MapEntry<String, dynamic>(key, value),
        ),
      );
    }).toList();
  }

  Future<bool> isFavorite(int productId) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.query(
      'Favorite',
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
    );
    return result.isNotEmpty;
  }

  Future<int> insertCart(int productId, int quantity) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> existing = await db.query(
      'Cart',
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
    );
    if (existing.isNotEmpty) {
      final int currentQty = existing.first['quantity'] as int;
      final int newQty = currentQty + quantity;
      return await db.update(
        'Cart',
        <String, Object?>{'quantity': newQty},
        where: 'productId = ?',
        whereArgs: <Object?>[productId],
      );
    }
    return await db.insert('Cart', {
      'productId': productId,
      'quantity': quantity,
    });
  }

  Future<int> updateCartQuantity(int productId, int quantity) async {
    final Database db = await instance.database;
    return await db.update(
      'Cart',
      {'quantity': quantity},
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
    );
  }

  Future<int> deleteCartItem(int productId) async {
    final Database db = await instance.database;
    return await db.delete(
      'Cart',
      where: 'productId = ?',
      whereArgs: <Object?>[productId],
    );
  }

  Future<void> clearCart() async {
    final Database db = await instance.database;
    await db.delete('Cart');
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> result = await db.rawQuery(
      'SELECT p.*, c.quantity, c.id AS cartItemId FROM Cart c INNER JOIN Product p ON c.productId = p.id',
    );
    return result
        .map((Map<String, Object?> json) => json.cast<String, dynamic>())
        .toList();
  }

  Future<int> insertNotification(
    AppNotification notification, {
    required List<String> recipientEmails,
  }) async {
    final Database db = await instance.database;
    return db.transaction((transaction) async {
      final int notificationId = await transaction.insert(
        'Notifications',
        notification.toJson(),
      );
      for (final String email in recipientEmails) {
        await transaction.insert('NotificationRecipients', <String, Object?>{
          'notificationId': notificationId,
          'userEmail': email.trim().toLowerCase(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return notificationId;
    });
  }

  Future<List<AppNotification>> getNotificationsForUser(
    String userEmail,
  ) async {
    final Database db = await instance.database;
    final String normalizedEmail = userEmail.trim().toLowerCase();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT n.*, CASE WHEN r.notificationId IS NULL THEN 0 ELSE 1 END AS isRead
      FROM Notifications n
      INNER JOIN NotificationRecipients nr
        ON nr.notificationId = n.id AND lower(nr.userEmail) = ?
      LEFT JOIN NotificationReads r
        ON r.notificationId = n.id AND lower(r.userEmail) = ?
      ORDER BY n.createdAt DESC, n.id DESC
      ''',
      <Object?>[normalizedEmail, normalizedEmail],
    );
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<List<AppNotification>> getNotificationsSentBy(
    String senderEmail,
  ) async {
    final Database db = await instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      'Notifications',
      where: 'lower(senderEmail) = ?',
      whereArgs: <Object?>[senderEmail.trim().toLowerCase()],
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<int> countUnreadNotifications(String userEmail) async {
    final Database db = await instance.database;
    final String normalizedEmail = userEmail.trim().toLowerCase();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM Notifications n
      INNER JOIN NotificationRecipients nr
        ON nr.notificationId = n.id AND lower(nr.userEmail) = ?
      LEFT JOIN NotificationReads r
        ON r.notificationId = n.id AND lower(r.userEmail) = ?
      WHERE r.notificationId IS NULL
      ''',
      <Object?>[normalizedEmail, normalizedEmail],
    );
    return rows.single['count'] as int;
  }

  Future<void> markNotificationRead({
    required int notificationId,
    required String userEmail,
  }) async {
    final Database db = await instance.database;
    await db.insert('NotificationReads', <String, Object?>{
      'notificationId': notificationId,
      'userEmail': userEmail.trim().toLowerCase(),
      'readAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
