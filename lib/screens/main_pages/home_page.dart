import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/shop_provider.dart';
import '../widgets/product_image.dart';
import 'cart_page.dart';
import 'category_page.dart';
import 'discount_coupons_page.dart';
import 'order_history_page.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';
import 'member_tier_page.dart';
import 'notifications_page.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<Category>? onCategorySelected;

  const HomePage({super.key, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        if (shopProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            const _ShopHeader(showLogo: true),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _MainBanner(),
                  const SizedBox(height: 12),

                  const _FeaturedPromoBanner(),
                  const SizedBox(height: 12),

                  const _ShortcutPanel(),
                  const SizedBox(height: 16),

                  const _SimplePromo(),
                  const SizedBox(height: 18),

                  _SectionTitle(title: 'Danh mục nổi bật'),

                  const SizedBox(height: 12),

                  _CategoryGrid(
                    categories: shopProvider.categories,
                    onCategorySelected: onCategorySelected,
                  ),

                  const SizedBox(height: 18),

                  _SectionTitle(title: 'Sản phẩm gợi ý'),

                  const SizedBox(height: 12),

                  _ProductGrid(products: shopProvider.products),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShopHeader extends StatefulWidget {
  final bool showLogo;

  const _ShopHeader({required this.showLogo});

  @override
  State<_ShopHeader> createState() => _ShopHeaderState();
}

class _ShopHeaderState extends State<_ShopHeader> {
  final TextEditingController _searchController = TextEditingController();
  late Future<int> _unreadCountFuture;

  @override
  void initState() {
    super.initState();
    _unreadCountFuture = _loadUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> _loadUnreadCount() async {
    final user = await AuthService.currentUser();
    if (user == null || user.role.toLowerCase() == 'admin') return 0;
    return NotificationService.getUnreadCount(user.email);
  }

  Future<void> _openNotifications() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const NotificationsPage()),
    );
    if (!mounted) return;
    setState(() => _unreadCountFuture = _loadUnreadCount());
  }

  void _navigateToSearch(BuildContext context, {String? query}) {
    final value = (query ?? _searchController.text).trim();
    if (value.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductListPage(searchQuery: value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const expandedHeight = 176.0;
    final collapsedHeight = topPadding + 88.0;

    return SliverAppBar(
      pinned: true,
      backgroundColor: appRed,
      elevation: 0,
      toolbarHeight: collapsedHeight,
      collapsedHeight: collapsedHeight,
      expandedHeight: expandedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final currentHeight = constraints.biggest.height;
          final progress =
              ((currentHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);
          final fieldHeight = Tween<double>(
            begin: 44,
            end: 54,
          ).transform(progress);
          final verticalGap = Tween<double>(
            begin: 10,
            end: 16,
          ).transform(progress);

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.showLogo)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    AppAssets.getImage('CellphoneS_Icon.png'),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'CellphoneS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _openNotifications,
                          icon: FutureBuilder<int>(
                            future: _unreadCountFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                debugPrint(
                                  'Could not load unread notifications: '
                                  '${snapshot.error}',
                                );
                              }
                              final count = snapshot.data ?? 0;
                              return Badge(
                                isLabelVisible: count > 0,
                                label: Text(count > 99 ? '99+' : '$count'),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalGap),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: fieldHeight,
                    width: double.infinity,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) =>
                          _navigateToSearch(context, query: value),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bạn muốn mua gì hôm nay?',
                        hintStyle: const TextStyle(
                          color: Color(0xff9ca3af),
                          fontSize: 15,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: IconButton(
                            splashRadius: 20,
                            icon: const Icon(
                              Icons.search,
                              color: Color(0xff6b7280),
                            ),
                            onPressed: () => _navigateToSearch(context),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 42,
                          minHeight: 42,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xfff43f5e),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox();

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;

  void _navigateToSearch(String query) {
    final value = query.trim();

    if (value.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductListPage(searchQuery: value)),
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (value.trim().isNotEmpty) {
        _navigateToSearch(value);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        onSubmitted: _navigateToSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,

          isDense: true,

          contentPadding: EdgeInsets.symmetric(vertical: 14),

          prefixIcon: Icon(Icons.search, color: Color(0xff6b7280), size: 24),

          prefixIconConstraints: BoxConstraints(minHeight: 48, minWidth: 48),

          hintText: "Bạn muốn mua gì hôm nay?",

          hintStyle: TextStyle(color: Color(0xff9ca3af), fontSize: 16),
        ),
      ),
    );
  }
}

class _MainBanner extends StatelessWidget {
  const _MainBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xff0f172a), Color(0xff1f2937)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Iphone 18 Pro Max",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Sản phẩm mới nhất",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                SizedBox(height: 18),
                _BannerPrice(),
              ],
            ),
          ),
          Image.asset(
            AppAssets.getImage("iphone18promax.png"),
            width: 118,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _BannerPrice extends StatelessWidget {
  const _BannerPrice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff97316),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        "Trả góp 0%",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FeaturedPromoBanner extends StatefulWidget {
  const _FeaturedPromoBanner();

  @override
  State<_FeaturedPromoBanner> createState() => _FeaturedPromoBannerState();
}

class _FeaturedPromoBannerState extends State<_FeaturedPromoBanner> {
  late final PageController _controller;
  int currentPage = 0;

  final List<_FeaturedPromoSlideData> slides = const [
    _FeaturedPromoSlideData(
      titlePrefix: "S24 Ultra",
      title: "Samsung Galaxy S24 Ultra",
      subtitle: "Galaxy AI",
      leftItems: [
        _PromoItem(label: "Giảm ngay", value: "2 Triệu"),
        _PromoItem(label: "Lên đời", value: "5 Triệu"),
      ],
      buttonLabel: "Đặt trước",
      image: "samsung_s24_ultra.png",
    ),
    _FeaturedPromoSlideData(
      titlePrefix: "Hot Deal",
      title: "iPhone 17 Pro Max",
      subtitle: "Flagship mới",
      leftItems: [
        _PromoItem(label: "Giảm", value: "3 Triệu"),
        _PromoItem(label: "Ưu đãi", value: "2 Triệu"),
      ],
      buttonLabel: "Xem ngay",
      image: "iphone17.png",
    ),
    _FeaturedPromoSlideData(
      titlePrefix: "Khuyến mãi",
      title: "Xiaomi 18 Pro",
      subtitle: "Hiệu năng siêu khủng",
      leftItems: [
        _PromoItem(label: "Giảm", value: "4 Triệu"),
        _PromoItem(label: "Trả góp", value: "0%"),
      ],
      buttonLabel: "Mua ngay",
      image: "xiaomi_18_pro.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _FeaturedPromoSlide(
                titlePrefix: slide.titlePrefix,
                title: slide.title,
                subtitle: slide.subtitle,
                leftItems: slide.leftItems,
                buttonLabel: slide.buttonLabel,
                image: slide.image,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: currentPage == index ? appRed : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedPromoSlideData {
  final String titlePrefix;
  final String title;
  final String subtitle;
  final List<_PromoItem> leftItems;
  final String buttonLabel;
  final String image;

  const _FeaturedPromoSlideData({
    required this.titlePrefix,
    required this.title,
    required this.subtitle,
    required this.leftItems,
    required this.buttonLabel,
    required this.image,
  });
}

class _FeaturedPromoSlide extends StatelessWidget {
  final String titlePrefix;
  final String title;
  final String subtitle;
  final List<_PromoItem> leftItems;
  final String buttonLabel;
  final String image;

  const _FeaturedPromoSlide({
    required this.titlePrefix,
    required this.title,
    required this.subtitle,
    required this.leftItems,
    required this.buttonLabel,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 250,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titlePrefix,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: leftItems.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    width: 116,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                const ProductListPage(),
                          ),
                        );
                      },
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Center(
                child: Image.asset(
                  AppAssets.getImage(image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoItem {
  final String label;
  final String value;

  const _PromoItem({required this.label, required this.value});
}

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.workspace_premium_outlined, 'Hạng thành viên'),
      (Icons.local_offer_outlined, 'Mã giảm giá'),
      (Icons.receipt_long_outlined, 'Lịch sử mua'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: item.$2 == 'Hạng thành viên'
                  ? () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const MemberTierPage(),
                        ),
                      );
                    }
                  : item.$2 == 'Lịch sử mua'
                  ? () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const OrderHistoryPage(),
                        ),
                      );
                    }
                  : item.$2 == 'Mã giảm giá'
                  ? () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const DiscountCouponsPage(),
                        ),
                      );
                    }
                  : null,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: appRed.withOpacity(.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.$1, color: appRed, size: 24),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimplePromo extends StatelessWidget {
  const _SimplePromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffff4d4d), Color(0xff3158e8)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Ưu đãi cực sốc giảm thêm đến 10%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Image.asset(
            AppAssets.getImage("iphone15.png"),
            width: 90,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xff111827),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category>? onCategorySelected;

  const _CategoryGrid({required this.categories, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (onCategorySelected != null) {
                onCategorySelected!(category);
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryPage(category: category),
                ),
              );
            },
            child: Container(
              width: 118,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffedf2f7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Image.asset(
                        AppAssets.getImage(category.image),
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xff111827),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        return _ProductTile(product: products[index]);
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: "vi_VN", symbol: "đ");

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: "product_${product.id}",
                      child: ProductImage(
                        source: product.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 0,
                    right: 0,
                    child: Consumer<ShopProvider>(
                      builder: (_, shop, __) {
                        final favorite = shop.isProductFavorite(product.id!);

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            shop.toggleFavorite(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              favorite ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: favorite ? Colors.red : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xff111827),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              currency.format(product.price),
              style: const TextStyle(
                color: appRed,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),

                const SizedBox(width: 4),

                Text(
                  product.rating.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                InkWell(
                  onTap: () async {
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
