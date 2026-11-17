import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../models/order.dart';
import '../../models/product_review.dart';
import '../../constants/app_colors.dart';
import '../widgets/product_image.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = Provider.of<ShopProvider>(context);
    final orders = shop.orders;
    final orderNumbers = calculateUserOrderNumbers(orders);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Bạn chưa có đơn hàng nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFormat.format(order.date)),
                        Text(
                          'Tổng cộng: ${currency.format(order.total)}',
                          style: const TextStyle(
                            color: appRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Thanh toán: ${order.paymentMethod.label}'),
                      ],
                    ),
                    trailing: _buildStatusBadge(order.status),
                    children: [
                      const Divider(),
                      ...order.items.map((item) {
                        ProductReview? review;
                        for (final ProductReview existingReview
                            in shop.reviews) {
                          if (existingReview.orderId == order.id &&
                              existingReview.productId == item.product.id) {
                            review = existingReview;
                            break;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ListTile(
                              leading: ProductImage(
                                source: item.product.image,
                                width: 40,
                                height: 40,
                              ),
                              title: Text(item.product.name),
                              subtitle: Text(
                                '${item.quantity} x ${currency.format(item.price)}',
                              ),
                              trailing: Text(
                                currency.format(item.quantity * item.price),
                              ),
                            ),
                            if (order.status == OrderStatus.delivered &&
                                order.id != null &&
                                item.product.id != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 8,
                                ),
                                child: review == null
                                    ? Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _showReviewDialog(
                                            context,
                                            shop,
                                            order,
                                            item,
                                          ),
                                          icon: const Icon(Icons.star),
                                          label: const Text(
                                            'Đánh giá sản phẩm',
                                          ),
                                        ),
                                      )
                                    : _buildReviewSummary(review),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildReviewSummary(ProductReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: List<Widget>.generate(5, (int index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            );
          }),
        ),
        if (review.comment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(review.comment),
          ),
      ],
    );
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    ShopProvider shop,
    OrderModel order,
    OrderItem item,
  ) {
    int selectedRating = 5;
    String comment = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) =>
              AlertDialog(
                title: Text('Đánh giá ${item.product.name}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Bạn chấm sản phẩm này bao nhiêu sao?'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(5, (int index) {
                          final int rating = index + 1;
                          return IconButton(
                            tooltip: '$rating sao',
                            onPressed: () {
                              setDialogState(() {
                                selectedRating = rating;
                              });
                            },
                            icon: Icon(
                              rating <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Nhận xét (không bắt buộc)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String value) => comment = value,
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(dialogContext);
                      final bool submitted = await shop.addProductReview(
                        orderId: order.id!,
                        productId: item.product.id!,
                        rating: selectedRating,
                        productName: item.product.name,
                        comment: comment,
                      );
                      if (!dialogContext.mounted) {
                        return;
                      }
                      if (submitted) {
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Cảm ơn bạn đã đánh giá'),
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Không thể gửi đánh giá cho đơn hàng này',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Gửi đánh giá'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String label;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'Đang xử lý';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case OrderStatus.shipping:
        color = Colors.purple;
        label = 'Đang giao';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'Đã giao';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
