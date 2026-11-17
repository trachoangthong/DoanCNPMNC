import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/shop_provider.dart';
import '../../constants/app_colors.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import '../widgets/product_image.dart';

class ProductListPage extends StatefulWidget {
  final Category? category;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String? searchQuery;

  const ProductListPage({
    super.key,
    this.category,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.searchQuery,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String searchQuery = '';
  double? minPrice;
  double? maxPrice;
  late final TextEditingController _searchController;
  Future<List<Product>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    minPrice = widget.initialMinPrice;
    maxPrice = widget.initialMaxPrice;
    searchQuery = widget.searchQuery ?? '';
    _searchController = TextEditingController(text: searchQuery);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> allProducts) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final normalizedCategory = widget.category?.name.toLowerCase();

    return allProducts.where((Product product) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);

      final matchesCategory =
          normalizedCategory == null ||
          normalizedCategory.isEmpty ||
          product.category.toLowerCase() == normalizedCategory;

      final matchesMinPrice = minPrice == null || product.price >= minPrice!;
      final matchesMaxPrice = maxPrice == null || product.price <= maxPrice!;

      return matchesQuery &&
          matchesCategory &&
          matchesMinPrice &&
          matchesMaxPrice;
    }).toList();
  }

  void _loadProducts() {
    final ShopProvider shop = Provider.of<ShopProvider>(context, listen: false);

    if (shop.products.isNotEmpty) {
      _productsFuture = Future.value(_filterProducts(shop.products));
      return;
    }

    _productsFuture = shop.getFilteredProducts(
      category: widget.category?.name,
      minPrice: minPrice,
      maxPrice: maxPrice,
      query: searchQuery,
    );
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    FocusScope.of(context).unfocus();
    setState(() {
      searchQuery = query;
      _loadProducts();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        double? localMin = minPrice;
        double? localMax = maxPrice;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Lọc sản phẩm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Khoảng giá (VNĐ)'),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Từ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String value) {
                            localMin = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Đến',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String value) {
                            localMax = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        setState(() {
                          minPrice = localMin;
                          maxPrice = localMax;
                          _loadProducts();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          minPrice = null;
                          maxPrice = null;
                          _loadProducts();
                        });
                        Navigator.pop(context);
                      },
                      child: const Center(child: Text('Xóa bộ lọc')),
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

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category?.name ??
              (searchQuery.isNotEmpty
                  ? 'Kết quả: "$searchQuery"'
                  : 'Tìm kiếm sản phẩm'),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) {
                setState(() {
                  searchQuery = value;
                });
              },
              onSubmitted: _submitSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<ShopProvider>(
        builder: (BuildContext context, ShopProvider shop, Widget? child) {
          return FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder:
                (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<Product> products = snapshot.data ?? <Product>[];

                  if (products.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await shop.refreshData();
                        setState(() {
                          _loadProducts();
                        });
                      },
                      child: ListView(
                        children: <Widget>[
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          const Center(
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('Không tìm thấy sản phẩm nào'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await shop.refreshData();
                      setState(() {
                        _loadProducts();
                      });
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: products.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Product product = products[index];
                        return _ProductCard(
                          product: product,
                          currency: currency,
                        );
                      },
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currency;

  const _ProductCard({required this.product, required this.currency});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Center(
                child: ProductImage(source: product.image, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              currency.format(product.price),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.availableQuantity <= 5)
              Text(
                'Chỉ còn ${product.availableQuantity} sản phẩm',
                style: const TextStyle(color: Colors.orange, fontSize: 10),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shop = Provider.of<ShopProvider>(
                    context,
                    listen: false,
                  );
                  await shop.addToCart(product);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const CartPage(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Mua ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
