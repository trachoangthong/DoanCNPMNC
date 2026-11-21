import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../data/database_helper.dart';
import '../../models/discount_coupon.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/shop_provider.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../widgets/product_image.dart';
import 'product_list_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  CartPageState createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final ShopProvider shop = Provider.of<ShopProvider>(context);
    final List<Map<String, dynamic>> cartItems = shop.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
        actions: <Widget>[
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearCartDialog(context, shop);
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> item = cartItems[index];
                      final Product product = Product.fromJson(item);
                      final int qty = item['quantity'] as int;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductImage(
                                source: product.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currency.format(product.price),
                                    style: const TextStyle(
                                      color: appRed,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      _qtyButton(Icons.remove, () {
                                        shop.updateCartQuantity(
                                          product.id!,
                                          qty - 1,
                                        );
                                      }),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _qtyButton(Icons.add, () {
                                        shop.updateCartQuantity(
                                          product.id!,
                                          qty + 1,
                                        );
                                      }),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          shop.removeFromCart(product.id!);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomBar(shop, currency),
              ],
            ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ProductListPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: appRed),
            child: const Text(
              'Mua sắm ngay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ShopProvider shop, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currency.format(shop.cartTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: appRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _handleCheckout(context, shop);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: appRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tiến hành thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, ShopProvider shop) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Xóa giỏ hàng?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              shop.clearCart();
              Navigator.pop(context);
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context, ShopProvider shop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => _CheckoutSheet(shop: shop),
    );
  }

  void refreshCart() {
    Provider.of<ShopProvider>(context, listen: false).refreshData();
  }
}

class _CheckoutSheet extends StatefulWidget {
  final ShopProvider shop;
  const _CheckoutSheet({required this.shop});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController couponController = TextEditingController();
  PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
  DiscountCoupon? appliedCoupon;
  String? couponFeedback;
  bool hasCouponError = false;
  bool isApplyingCoupon = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSignedInUser();
  }

  Future<void> _loadSignedInUser() async {
    final UserModel? user = await AuthService.currentUser();
    if (!mounted || user == null) {
      return;
    }

    nameController.text = user.fullName;
    phoneController.text = user.phone;
    final String address = user.address.trim();
    final String city = user.city.trim();
    addressController.text = address.isEmpty || city.isEmpty
        ? address
        : '$address, $city';
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    couponController.dispose();
    super.dispose();
  }

  double get discountAmount {
    final DiscountCoupon? coupon = appliedCoupon;
    if (coupon == null) return 0;
    return widget.shop.cartTotal * coupon.discountPercent / 100;
  }

  double get totalToPay => widget.shop.cartTotal - discountAmount;

  Future<void> _applyCoupon() async {
    final String code = couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        appliedCoupon = null;
        couponFeedback = 'Vui lòng nhập mã giảm giá';
        hasCouponError = true;
      });
      return;
    }

    setState(() {
      isApplyingCoupon = true;
      appliedCoupon = null;
      couponFeedback = null;
      hasCouponError = false;
    });

    try {
      final List<DiscountCoupon> coupons = await DatabaseHelper.instance
          .getDiscountCoupons();
      DiscountCoupon? coupon;
      for (final DiscountCoupon candidate in coupons) {
        if (candidate.code.trim().toUpperCase() == code) {
          coupon = candidate;
          break;
        }
      }

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      if (coupon == null ||
          !coupon.isActive ||
          coupon.discountPercent <= 0 ||
          coupon.discountPercent > 100 ||
          DateTime(
            coupon.expiresAt.year,
            coupon.expiresAt.month,
            coupon.expiresAt.day,
          ).isBefore(today)) {
        if (mounted) {
          setState(() {
            couponFeedback = 'Mã không hợp lệ, đã hết hạn hoặc đã bị tắt';
            hasCouponError = true;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          appliedCoupon = coupon;
          couponFeedback = 'Đã áp dụng mã giảm ${coupon!.discountPercent}%';
          hasCouponError = false;
        });
      }
    } catch (error) {
      debugPrint('Error applying discount coupon: $error');
      if (mounted) {
        setState(() {
          couponFeedback = 'Không thể kiểm tra mã. Vui lòng thử lại.';
          hasCouponError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => isApplyingCoupon = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Thông tin nhận hàng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ nhận hàng',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: couponController,
                    enabled: !isApplyingCoupon && !isSubmitting,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Mã giảm giá',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String value) {
                      if (appliedCoupon != null &&
                          value.trim().toUpperCase() != appliedCoupon!.code) {
                        setState(() {
                          appliedCoupon = null;
                          couponFeedback = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isApplyingCoupon || isSubmitting
                        ? null
                        : _applyCoupon,
                    child: isApplyingCoupon
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
            if (couponFeedback != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                couponFeedback!,
                style: TextStyle(
                  color: hasCouponError ? appRed : Colors.green.shade700,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: isSubmitting,
              child: RadioGroup<PaymentMethod>(
                groupValue: selectedPaymentMethod,
                onChanged: (PaymentMethod? value) {
                  if (value != null) {
                    setState(() => selectedPaymentMethod = value);
                  }
                },
                child: Column(
                  children:
                      <PaymentMethod>[
                        PaymentMethod.cash,
                        PaymentMethod.vnpay,
                      ].map((PaymentMethod method) {
                        final IconData icon = switch (method) {
                          PaymentMethod.cash => Icons.payments_outlined,
                          PaymentMethod.bankTransfer =>
                            Icons.account_balance_outlined,
                          PaymentMethod.vnpay => Icons.qr_code_2,
                        };
                        return RadioListTile<PaymentMethod>(
                          value: method,
                          secondary: Icon(icon, color: appRed),
                          title: Text(method.label),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: appRed,
                        );
                      }).toList(),
                ),
              ),
            ),
            if (selectedPaymentMethod == PaymentMethod.vnpay) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Quét mã bằng ứng dụng ngân hàng hoặc VNPay',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/vnpay_qr.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            debugPrint('Không thể tải mã QR VNPay: $error');
                            return const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Text('Không thể tải mã QR thanh toán.'),
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Số tiền cần thanh toán: '
                      '${currency.format(totalToPay)}',
                      style: const TextStyle(
                        color: appRed,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đây là mã QR tĩnh do bạn cung cấp; ứng dụng chưa xác minh giao dịch. '
                'Vui lòng kiểm tra người nhận và số tiền trước khi xác nhận.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 20),
            if (appliedCoupon != null) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Giảm giá (${appliedCoupon!.code})'),
                  Text(
                    '-${currency.format(discountAmount)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Tổng thanh toán:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currency.format(totalToPay),
                  style: const TextStyle(
                    color: appRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameController.text.isEmpty ||
                            phoneController.text.isEmpty ||
                            addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập đầy đủ thông tin'),
                            ),
                          );
                          return;
                        }

                        final ScaffoldMessengerState messenger =
                            ScaffoldMessenger.of(context);
                        final NavigatorState navigator = Navigator.of(context);
                        setState(() => isSubmitting = true);
                        bool placed = false;
                        try {
                          placed = await widget.shop.placeOrder(
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            paymentMethod: selectedPaymentMethod,
                            discountAmount: discountAmount,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }

                        if (!mounted) {
                          return;
                        }
                        if (!placed) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đặt hàng thất bại. Vui lòng thử lại.',
                              ),
                            ),
                          );
                          return;
                        }
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Đặt hàng thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Xác nhận đặt hàng',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
