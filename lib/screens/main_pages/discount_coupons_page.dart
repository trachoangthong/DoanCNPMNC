import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../data/database_helper.dart';
import '../../models/discount_coupon.dart';

class DiscountCouponsPage extends StatefulWidget {
  const DiscountCouponsPage({super.key});

  @override
  State<DiscountCouponsPage> createState() => _DiscountCouponsPageState();
}

class _DiscountCouponsPageState extends State<DiscountCouponsPage> {
  late Future<List<DiscountCoupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = DatabaseHelper.instance.getDiscountCoupons();
  }

  Future<void> _refreshCoupons() async {
    final Future<List<DiscountCoupon>> request = DatabaseHelper.instance
        .getDiscountCoupons();
    setState(() {
      _couponsFuture = request;
    });
    await request;
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép mã giảm giá')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã giảm giá'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<DiscountCoupon>>(
        future: _couponsFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<DiscountCoupon>> snapshot,
            ) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Không thể tải mã giảm giá: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final DateTime today = DateTime.now();
              final DateTime todayDate = DateTime(
                today.year,
                today.month,
                today.day,
              );
              final List<DiscountCoupon> availableCoupons = snapshot.data!
                  .where((DiscountCoupon coupon) {
                    final DateTime expiryDate = DateTime(
                      coupon.expiresAt.year,
                      coupon.expiresAt.month,
                      coupon.expiresAt.day,
                    );
                    return coupon.isActive && !expiryDate.isBefore(todayDate);
                  })
                  .toList();

              return RefreshIndicator(
                onRefresh: _refreshCoupons,
                child: availableCoupons.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const <Widget>[
                          SizedBox(height: 180),
                          Center(child: Text('Hiện chưa có mã giảm giá')),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: availableCoupons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final DiscountCoupon coupon = availableCoupons[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xfffde8ea),
                                child: Icon(Icons.local_offer, color: appRed),
                              ),
                              title: Text(
                                '${coupon.discountPercent}% giảm giá',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('Mã: ${coupon.code}'),
                                    Text(
                                      'Hạn dùng: ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt)}',
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'Sao chép mã',
                                onPressed: () => _copyCode(coupon.code),
                                icon: const Icon(Icons.copy),
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
      ),
    );
  }
}
