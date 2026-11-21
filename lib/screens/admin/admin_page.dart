import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/user_model.dart';
import '../../models/order.dart';
import '../../models/member_tier.dart';
import '../../services/shop_provider.dart';
import 'admin_discount_coupon_page.dart';
import 'admin_member_tier_page.dart';
import 'admin_notifications_page.dart';
import 'admin_product_reviews_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị hệ thống'),
          backgroundColor: appRed,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            onTap: (int index) {
              if (index == 4 || index == 6) {
                unawaited(
                  Provider.of<ShopProvider>(
                    context,
                    listen: false,
                  ).refreshData(),
                );
              }
            },
            tabs: const <Widget>[
              Tab(icon: Icon(Icons.shopping_bag), text: 'Sản phẩm'),
              Tab(icon: Icon(Icons.category), text: 'Danh mục'),
              Tab(icon: Icon(Icons.people), text: 'Thành viên'),
              Tab(icon: Icon(Icons.workspace_premium), text: 'Hạng thành viên'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Đơn hàng'),
              Tab(icon: Icon(Icons.local_offer), text: 'Mã giảm giá'),
              Tab(icon: Icon(Icons.rate_review), text: 'Đánh giá'),
              Tab(icon: Icon(Icons.notifications), text: 'Thông báo'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _ProductManager(),
            _CategoryManager(),
            _UserManager(),
            AdminMemberTierPage(),
            _OrderManager(),
            AdminDiscountCouponPage(),
            AdminProductReviewsPage(),
            AdminNotificationsPage(),
          ],
        ),
      ),
    );
  }
}

class _ProductManager extends StatelessWidget {
  const _ProductManager();

  @override
  Widget build(BuildContext context) {
    final BuildContext managerContext = context;
    final TabController tabController = DefaultTabController.of(context);

    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: appRed,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final bool? saved = await _showProductDialog(context);
              if (saved == true && managerContext.mounted) {
                tabController.animateTo(0);
              }
            },
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: shop.products.length,
            itemBuilder: (BuildContext context, int index) {
              final Product p = shop.products[index];
              return Card(
                child: ListTile(
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.category} - ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(p.price)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final bool? saved = await _showProductDialog(
                            context,
                            product: p,
                          );
                          if (saved == true && managerContext.mounted) {
                            tabController.animateTo(0);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (p.id != null) {
                            shop.deleteProduct(p.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool?> _showProductDialog(BuildContext context, {Product? product}) {
    final ShopProvider shop = Provider.of<ShopProvider>(context, listen: false);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _ProductDialog(shop: shop, product: product),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final ShopProvider shop;
  final Product? product;

  const _ProductDialog({required this.shop, this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _specificationsCtrl;
  late String _selectedCat;

  @override
  void initState() {
    super.initState();
    final Product? product = widget.product;
    _nameCtrl = TextEditingController(text: product?.name);
    _priceCtrl = TextEditingController(text: product?.price.toString());
    _descCtrl = TextEditingController(text: product?.description);
    _imageCtrl = TextEditingController(text: product?.image);
    _quantityCtrl = TextEditingController(
      text: product?.availableQuantity.toString() ?? '10',
    );
    _specificationsCtrl = TextEditingController(text: product?.specifications);
    _selectedCat =
        product?.category ??
        (widget.shop.categories.isNotEmpty
            ? widget.shop.categories[0].name
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _quantityCtrl.dispose();
    _specificationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
      dialogContext,
    );
    final Product? product = widget.product;
    final Product newProduct = Product(
      id: product?.id,
      name: _nameCtrl.text.trim(),
      price: double.parse(_priceCtrl.text),
      description: _descCtrl.text.trim(),
      category: _selectedCat,
      image: _imageCtrl.text.trim(),
      availableQuantity: int.parse(_quantityCtrl.text),
      specifications: _specificationsCtrl.text.trim(),
      discount: product?.discount ?? 0,
      rating: product?.rating ?? 4.5,
      reviewCount: product?.reviewCount ?? 0,
      images: product?.images ?? const <String>[],
    );

    final bool saved;
    if (product == null) {
      saved = await widget.shop.addProduct(newProduct) > 0;
    } else {
      saved = await widget.shop.updateProduct(newProduct);
    }

    if (!dialogContext.mounted) {
      return;
    }

    if (saved) {
      Navigator.pop(dialogContext, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? 'Thêm sản phẩm thành công'
                : 'Cập nhật sản phẩm thành công',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể lưu sản phẩm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShopProvider shop = widget.shop;
    final Product? product = widget.product;

    return AlertDialog(
      title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên sản phẩm'
                    : null,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  final double? price = double.tryParse(value ?? '');
                  return price == null || price <= 0
                      ? 'Vui lòng nhập giá hợp lệ'
                      : null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedCat.isEmpty && shop.categories.isNotEmpty
                    ? shop.categories[0].name
                    : (_selectedCat.isNotEmpty ? _selectedCat : null),
                items: shop.categories.map<DropdownMenuItem<String>>((
                  Category category,
                ) {
                  return DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    _selectedCat = value;
                  }
                },
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (String? value) =>
                    value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link ảnh sản phẩm',
                  hintText: 'Dán địa chỉ hình ảnh trực tiếp (https://...)',
                  helperText:
                      'Trên Google Hình ảnh, chọn "Sao chép địa chỉ hình ảnh".',
                ),
                keyboardType: TextInputType.url,
                validator: (String? value) {
                  final String image = value?.trim() ?? '';
                  if (image.isEmpty) {
                    return 'Vui lòng nhập link ảnh sản phẩm';
                  }
                  final Uri? uri = Uri.tryParse(image);
                  final bool isWebUrl =
                      uri != null &&
                      (uri.scheme == 'http' || uri.scheme == 'https') &&
                      uri.host.isNotEmpty;
                  final bool unchangedExistingAsset =
                      product != null &&
                      image == product.image &&
                      !(product.image.startsWith('http://') ||
                          product.image.startsWith('https://'));
                  return isWebUrl || unchangedExistingAsset
                      ? null
                      : 'Vui lòng nhập địa chỉ ảnh http hoặc https';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  final int? quantity = int.tryParse(value ?? '');
                  return quantity == null || quantity < 0
                      ? 'Vui lòng nhập số lượng hợp lệ'
                      : null;
                },
              ),
              TextFormField(
                controller: _specificationsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thông số kỹ thuật',
                ),
                maxLines: 2,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => _save(context),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _CategoryManager extends StatelessWidget {
  const _CategoryManager();

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showCategoryDialog(context);
            },
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: shop.categories.length,
            itemBuilder: (BuildContext context, int index) {
              final Category cat = shop.categories[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.category, color: Colors.orange),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showCategoryDialog(context, category: cat);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (cat.id != null) {
                            shop.deleteCategory(cat.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final ShopProvider shop = Provider.of<ShopProvider>(context, listen: false);
    final TextEditingController nameCtrl = TextEditingController(
      text: category?.name,
    );
    final TextEditingController descCtrl = TextEditingController(
      text: category?.description,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final Category newCat = Category(
                  id: category?.id,
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  image: category?.image ?? 'iphone.png',
                );
                if (category == null) {
                  shop.addCategory(newCat);
                } else {
                  shop.updateCategory(newCat);
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}

class _UserManager extends StatelessWidget {
  const _UserManager();

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        final NumberFormat currency = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        );
        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: shop.users.length,
            itemBuilder: (BuildContext context, int index) {
              final UserModel user = shop.users[index];
              final bool isAdmin = user.role.toLowerCase() == 'admin';
              final MemberTierSummary tierSummary =
                  MemberTierSummary.fromOrders(
                    shop.orders
                        .where(
                          (OrderModel order) =>
                              order.userEmail?.trim().toLowerCase() ==
                              user.email.trim().toLowerCase(),
                        )
                        .toList(),
                  );
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.avatar),
                    onBackgroundImageError:
                        (Object exception, StackTrace? stackTrace) {
                          debugPrint('Error loading avatar: $exception');
                        },
                    child: user.avatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('${user.email} - Quyền: ${user.role}'),
                      Text(
                        'Địa chỉ: ${<String>[user.address.trim(), user.city.trim()].where((String part) => part.isNotEmpty).join(', ')}',
                      ),
                      if (!isAdmin) ...<Widget>[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Chip(
                              avatar: const Icon(
                                Icons.workspace_premium,
                                size: 18,
                              ),
                              label: Text('Hạng ${tierSummary.tier.name}'),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            Text(
                              '${currency.format(tierSummary.tier.totalSpent)}'
                              ' • ${tierSummary.completedOrderCount} đơn đã giao',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showUserDialog(context, user);
                        },
                      ),
                      if (user.role != 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            shop.deleteUser(user.email);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showUserDialog(BuildContext context, UserModel user) {
    final ShopProvider shop = Provider.of<ShopProvider>(context, listen: false);
    final TextEditingController nameCtrl = TextEditingController(
      text: user.fullName,
    );
    final TextEditingController phoneCtrl = TextEditingController(
      text: user.phone,
    );
    final TextEditingController addressCtrl = TextEditingController(
      text: user.address,
    );
    String selectedRole = user.role;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sửa thông tin thành viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'SĐT'),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'user',
                    child: Text('Người dùng'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'admin',
                    child: Text('Quản trị viên'),
                  ),
                ],
                onChanged: (String? v) {
                  if (v != null) {
                    selectedRole = v;
                  }
                },
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final UserModel updatedUser = UserModel(
                  fullName: nameCtrl.text,
                  email: user.email,
                  phone: phoneCtrl.text,
                  password: user.password,
                  avatar: user.avatar,
                  gender: user.gender,
                  city: user.city,
                  address: addressCtrl.text,
                  role: selectedRole,
                );
                shop.updateUser(updatedUser);
                Navigator.pop(context);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }
}

class _OrderManager extends StatelessWidget {
  const _OrderManager();

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipping:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xử lý';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        if (shop.orders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào'));
        }

        final Map<int, int> orderNumbers = calculateUserOrderNumbers(
          shop.orders,
        );
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: shop.orders.length,
          itemBuilder: (BuildContext context, int index) {
            final OrderModel order = shop.orders[index];
            final int orderNumber = order.id == null
                ? index + 1
                : orderNumbers[order.id] ?? order.id!;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  'Đơn hàng #$orderNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(order.date)}'
                  '\nTổng: ${currency.format(order.total)}'
                  '\nThanh toán: ${order.paymentMethod.label}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusName(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                children: <Widget>[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Thông tin khách hàng',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Họ tên: ${order.customerName}'),
                        Text(
                          'Số điện thoại: ${order.customerPhone.isEmpty ? 'Chưa cung cấp' : order.customerPhone}',
                        ),
                        Text(
                          'Địa chỉ: ${order.address.isEmpty ? 'Chưa cung cấp' : order.address}',
                        ),
                        if (order.userEmail?.isNotEmpty ?? false)
                          Text('Email: ${order.userEmail}'),
                      ],
                    ),
                  ),
                  const Divider(),
                  ...order.items.map((OrderItem item) {
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        'SL: ${item.quantity} x ${currency.format(item.price)}',
                      ),
                    );
                  }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        const Text('Cập nhật trạng thái: '),
                        DropdownButton<OrderStatus>(
                          value: order.status,
                          items: OrderStatus.values.map((OrderStatus s) {
                            return DropdownMenuItem<OrderStatus>(
                              value: s,
                              child: Text(_getStatusName(s)),
                            );
                          }).toList(),
                          onChanged: (OrderStatus? newStatus) {
                            if (newStatus != null && order.id != null) {
                              shop.updateOrderStatus(order.id!, newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
