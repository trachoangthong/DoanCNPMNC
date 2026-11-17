import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../models/category.dart';
import '../../constants/app_colors.dart';
import 'product_list_page.dart';

class CategoryPage extends StatefulWidget {
  final Category? category;
  const CategoryPage({super.key, this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int? selectedIndex;

  @override
  void didUpdateWidget(covariant CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category?.id != widget.category?.id ||
        oldWidget.category?.name != widget.category?.name) {
      selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeeeeef),
      body: SafeArea(
        child: Consumer<ShopProvider>(
          builder: (context, shop, child) {
            final categories = shop.categories;
            if (categories.isEmpty) {
              return const Center(child: Text('Không có danh mục nào'));
            }

            final requestedIndex = widget.category == null
                ? -1
                : categories.indexWhere(
                    (category) => widget.category!.id != null
                        ? category.id == widget.category!.id
                        : category.name == widget.category!.name,
                  );
            final currentIndex =
                selectedIndex != null && selectedIndex! < categories.length
                ? selectedIndex!
                : requestedIndex >= 0
                ? requestedIndex
                : 0;

            return Column(
              children: [
                const _RedSearchHeader(),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        child: ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = index == currentIndex;
                            return InkWell(
                              onTap: () =>
                                  setState(() => selectedIndex = index),
                              child: Container(
                                height: 108,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xfff7f7f8),
                                  border: Border(
                                    left: BorderSide(
                                      width: 5,
                                      color: selected
                                          ? appRed
                                          : Colors.transparent,
                                    ),
                                    bottom: const BorderSide(
                                      color: Color(0xffdddddf),
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _CategoryDetailView(
                          category: categories[currentIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryDetailView extends StatelessWidget {
  final Category category;
  const _CategoryDetailView({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _CategorySection(
          title: category.name,
          trailing: 'Xem tất cả',
          onTrailingTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListPage(category: category),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (category.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category.description,
                    style: const TextStyle(
                      color: Color(0xff333333),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CategorySection(
          title: 'Phân khúc giá',
          child: _PriceFilterGrid(category: category),
        ),
      ],
    );
  }
}

class _PriceFilterGrid extends StatelessWidget {
  final Category category;
  const _PriceFilterGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('Dưới 5 triệu', null, 5000000.0),
      ('5 - 10 triệu', 5000000.0, 10000000.0),
      ('10 - 20 triệu', 10000000.0, 20000000.0),
      ('Trên 20 triệu', 20000000.0, null),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((f) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListPage(
                  category: category,
                  initialMinPrice: f.$2,
                  initialMaxPrice: f.$3,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(f.$1, style: const TextStyle(fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}

class _RedSearchHeader extends StatelessWidget {
  const _RedSearchHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appRed,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: const Row(
          children: [
            Icon(Icons.search, size: 24, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bạn muốn mua gì hôm nay?',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xffc7c7cc), fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _CategorySection({
    required this.title,
    required this.child,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                GestureDetector(
                  onTap: onTrailingTap,
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: Color(0xff3c86ff),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
