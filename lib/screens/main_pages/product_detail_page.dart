import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_review.dart';
import '../../services/shop_provider.dart';
import '../widgets/product_image.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  List<Product> relatedProducts = <Product>[];
  late Future<List<ProductReview>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadProductReviews();
    _loadRelatedProducts();
  }

  Future<List<ProductReview>> _loadProductReviews() {
    final int? productId = widget.product.id;
    if (productId == null) {
      return Future<List<ProductReview>>.value(<ProductReview>[]);
    }

    return Provider.of<ShopProvider>(
      context,
      listen: false,
    ).getProductReviewsByProduct(productId);
  }

  Future<void> _loadRelatedProducts() async {
    final ShopProvider shop = Provider.of<ShopProvider>(context, listen: false);
    final List<Product> products = await shop.getProductsByCategory(
      widget.product.category,
    );
    if (mounted) {
      setState(() {
        relatedProducts = products
            .where((Product p) => p.id != widget.product.id)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final ShopProvider shopProvider = Provider.of<ShopProvider>(context);
    final bool isFavorite = shopProvider.isProductFavorite(
      widget.product.id ?? -1,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              shopProvider.toggleFavorite(widget.product);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: Hero(
                tag: 'product_${widget.product.id}',
                child: ProductImage(
                  source: widget.product.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        widget.product.category.toUpperCase(),
                        style: const TextStyle(
                          color: appRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(
                            ' ${widget.product.rating} (${widget.product.reviewCount} đánh giá)',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Text(
                        currency.format(widget.product.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: appRed,
                        ),
                      ),
                      if (widget.product.discount > 0) ...<Widget>[
                        const SizedBox(width: 10),
                        Text(
                          currency.format(
                            widget.product.price /
                                (1 - widget.product.discount / 100),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Thông số kỹ thuật',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.specifications.isEmpty
                        ? "Đang cập nhật"
                        : widget.product.specifications,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildProductReviews(),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Số lượng:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _qtyBtn(Icons.remove, () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _qtyBtn(Icons.add, () {
                        if (quantity < widget.product.availableQuantity) {
                          setState(() {
                            quantity++;
                          });
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (relatedProducts.isNotEmpty) ...<Widget>[
                    const Text(
                      'Sản phẩm liên quan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedProducts.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Product p = relatedProducts[index];
                          return _RelatedProductCard(
                            product: p,
                            currency: currency,
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomButtons(context, shopProvider),
    );
  }

  Widget _buildProductReviews() {
    return FutureBuilder<List<ProductReview>>(
      future: _reviewsFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<ProductReview>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Không thể tải đánh giá sản phẩm.');
            }

            final List<ProductReview> reviews =
                snapshot.data ?? <ProductReview>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Đánh giá sản phẩm (${reviews.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  const Text('Sản phẩm chưa có đánh giá.')
                else
                  ...reviews.map((ProductReview review) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    review.userName.isEmpty
                                        ? 'Người mua'
                                        : review.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(review.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List<Widget>.generate(5, (int index) {
                                return Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            if (review.comment.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(review.comment),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, ShopProvider shopProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                shopProvider.addToCart(widget.product, quantity: quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: appRed),
              ),
              child: const Text(
                'Thêm vào giỏ',
                style: TextStyle(color: appRed, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await shopProvider.addToCart(
                  widget.product,
                  quantity: quantity,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const CartPage(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Mua ngay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currency;

  const _RelatedProductCard({required this.product, required this.currency});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext _) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ProductImage(source: product.image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              currency.format(product.price),
              style: const TextStyle(
                fontSize: 12,
                color: appRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
