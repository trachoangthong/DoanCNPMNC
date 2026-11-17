import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product_review.dart';
import '../../services/shop_provider.dart';

class AdminProductReviewsPage extends StatelessWidget {
  const AdminProductReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        if (shop.reviews.isEmpty) {
          return const Center(child: Text('Chưa có đánh giá sản phẩm'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: shop.reviews.length,
          itemBuilder: (BuildContext context, int index) {
            final ProductReview review = shop.reviews[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  review.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${review.userName} (${review.userEmail})'),
                      const SizedBox(height: 4),
                      Row(
                        children: List<Widget>.generate(5, (int starIndex) {
                          return Icon(
                            starIndex < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      if (review.comment.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(review.comment),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
