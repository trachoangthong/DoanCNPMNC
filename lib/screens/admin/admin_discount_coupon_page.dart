import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../data/database_helper.dart';
import '../../models/discount_coupon.dart';

class AdminDiscountCouponPage extends StatefulWidget {
  const AdminDiscountCouponPage({super.key});

  @override
  State<AdminDiscountCouponPage> createState() =>
      _AdminDiscountCouponPageState();
}

class _AdminDiscountCouponPageState extends State<AdminDiscountCouponPage> {
  List<DiscountCoupon> _coupons = <DiscountCoupon>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCoupons());
  }

  Future<void> _loadCoupons() async {
    try {
      final List<DiscountCoupon> coupons = await DatabaseHelper.instance
          .getDiscountCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading discount coupons: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải danh sách mã giảm giá')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: appRed,
        tooltip: 'Thêm mã giảm giá',
        onPressed: () => _showCouponDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
          ? const Center(child: Text('Chưa có mã giảm giá'))
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _coupons.length,
                itemBuilder: (BuildContext context, int index) {
                  final DiscountCoupon coupon = _coupons[index];
                  final DateTime today = DateTime.now();
                  final DateTime expiryDate = DateTime(
                    coupon.expiresAt.year,
                    coupon.expiresAt.month,
                    coupon.expiresAt.day,
                  );
                  final bool isExpired = expiryDate.isBefore(
                    DateTime(today.year, today.month, today.day),
                  );
                  final String status = isExpired
                      ? 'Đã hết hạn'
                      : coupon.isActive
                      ? 'Đang áp dụng'
                      : 'Đã tắt';

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_offer, color: appRed),
                      title: Text(
                        coupon.code,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${coupon.discountPercent}% giảm giá • Hạn: ${DateFormat('dd/MM/yyyy').format(coupon.expiresAt)} • $status',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Sửa mã giảm giá',
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCouponDialog(coupon: coupon),
                          ),
                          IconButton(
                            tooltip: 'Xóa mã giảm giá',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCoupon(coupon),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showCouponDialog({DiscountCoupon? coupon}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String code = coupon?.code ?? '';
    String discountText = coupon?.discountPercent.toString() ?? '';
    DateTime expiresAt =
        coupon?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = coupon?.isActive ?? true;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  title: Text(
                    coupon == null ? 'Thêm mã giảm giá' : 'Sửa mã giảm giá',
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            initialValue: code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Mã giảm giá',
                            ),
                            onSaved: (String? value) {
                              code = value?.trim() ?? '';
                            },
                            validator: (String? value) =>
                                value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập mã giảm giá'
                                : null,
                          ),
                          TextFormField(
                            initialValue: discountText,
                            decoration: const InputDecoration(
                              labelText: 'Mức giảm (%)',
                            ),
                            onSaved: (String? value) {
                              discountText = value?.trim() ?? '';
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (String? value) {
                              final double? percent = double.tryParse(
                                value ?? '',
                              );
                              return percent == null ||
                                      percent <= 0 ||
                                      percent > 100
                                  ? 'Nhập mức giảm từ 0 đến 100%'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? selected = await showDatePicker(
                                  context: context,
                                  initialDate: expiresAt,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (selected != null) {
                                  setDialogState(() {
                                    expiresAt = selected;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                'Hạn: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                              ),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Đang áp dụng'),
                            value: isActive,
                            onChanged: (bool value) {
                              setDialogState(() => isActive = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        formKey.currentState!.save();

                        final DiscountCoupon newCoupon = DiscountCoupon(
                          id: coupon?.id,
                          code: code.toUpperCase(),
                          discountPercent: double.parse(discountText),
                          expiresAt: DateTime(
                            expiresAt.year,
                            expiresAt.month,
                            expiresAt.day,
                          ),
                          isActive: isActive,
                        );

                        try {
                          if (coupon == null) {
                            await DatabaseHelper.instance.insertDiscountCoupon(
                              newCoupon,
                            );
                          } else {
                            await DatabaseHelper.instance.updateDiscountCoupon(
                              newCoupon,
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (error) {
                          debugPrint('Error saving discount coupon: $error');
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không thể lưu mã. Mã có thể đã tồn tại.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (saved == true && mounted) {
      await _loadCoupons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            coupon == null
                ? 'Thêm mã giảm giá thành công'
                : 'Cập nhật mã giảm giá thành công',
          ),
        ),
      );
    }
  }

  Future<void> _deleteCoupon(DiscountCoupon coupon) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa mã giảm giá'),
          content: Text('Bạn có chắc muốn xóa mã "${coupon.code}" không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || coupon.id == null) return;

    try {
      await DatabaseHelper.instance.deleteDiscountCoupon(coupon.id!);
      await _loadCoupons();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa mã giảm giá')));
    } catch (error) {
      debugPrint('Error deleting discount coupon: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa mã giảm giá')),
      );
    }
  }
}
