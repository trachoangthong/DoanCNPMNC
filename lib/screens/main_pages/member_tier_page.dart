import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/member_tier.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../data/database_helper.dart';

class MemberTierPage extends StatefulWidget {
  const MemberTierPage({super.key});

  @override
  State<MemberTierPage> createState() => _MemberTierPageState();
}

class _MemberTierPageState extends State<MemberTierPage> {
  late Future<MemberTierSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<MemberTierSummary> _loadSummary() async {
    final UserModel? user = await AuthService.currentUser();
    if (user == null) {
      throw StateError('Không tìm thấy tài khoản đang đăng nhập.');
    }

    final orders = await DatabaseHelper.instance.getOrdersByUser(user.email);
    return MemberTierSummary.fromOrders(orders);
  }

  void _retry() {
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hạng thành viên'),
        backgroundColor: appRed,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<MemberTierSummary>(
        future: _summaryFuture,
        builder: (BuildContext context, AsyncSnapshot<MemberTierSummary> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Không thể tải thông tin hạng thành viên.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final MemberTierSummary summary = snapshot.data!;
          final MemberTier tier = summary.tier;
          final int? remaining = tier.remainingToNextTier;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xff9f1239), appRed],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 52,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hạng ${tier.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      currency.format(tier.totalSpent),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Tổng chi tiêu từ đơn hàng đã giao',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        remaining == null
                            ? 'Bạn đang ở hạng cao nhất!'
                            : 'Tiến độ lên hạng ${_nextTierName(tier.name)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (remaining != null) ...<Widget>[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: tier.progressToNextTier,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          color: appRed,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mua thêm ${currency.format(remaining)} để đạt hạng ${_nextTierName(tier.name)}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${summary.completedOrderCount} đơn hàng đã giao được tính',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Các mức hạng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _TierRow(
                name: 'Đồng',
                range: 'Đến ${currency.format(MemberTier.bronzeMaximum)}',
                active: tier.name == 'Đồng',
              ),
              _TierRow(
                name: 'Bạc',
                range:
                    '${currency.format(MemberTier.bronzeMaximum + 1)} – ${currency.format(MemberTier.silverMaximum)}',
                active: tier.name == 'Bạc',
              ),
              _TierRow(
                name: 'Vàng',
                range:
                    '${currency.format(MemberTier.silverMaximum + 1)} – ${currency.format(MemberTier.goldMaximum)}',
                active: tier.name == 'Vàng',
              ),
              _TierRow(
                name: 'Kim cương',
                range: 'Từ ${currency.format(MemberTier.goldMaximum + 1)}',
                active: tier.name == 'Kim cương',
              ),
              const SizedBox(height: 8),
              const Text(
                'Chỉ đơn hàng đã giao thành công được cộng vào tổng chi tiêu. '
                'Đơn đang xử lý, đang giao hoặc đã hủy không được tính.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  String _nextTierName(String currentTier) {
    switch (currentTier) {
      case 'Đồng':
        return 'Bạc';
      case 'Bạc':
        return 'Vàng';
      case 'Vàng':
        return 'Kim cương';
      default:
        return 'Kim cương';
    }
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.name,
    required this.range,
    required this.active,
  });

  final String name;
  final String range;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: active ? const Color(0xfffff1f2) : Colors.white,
      child: ListTile(
        leading: Icon(
          Icons.workspace_premium_outlined,
          color: active ? appRed : Colors.grey,
        ),
        title: Text(
          'Hạng $name',
          style: TextStyle(fontWeight: active ? FontWeight.bold : null),
        ),
        subtitle: Text(range),
        trailing: active ? const Icon(Icons.check_circle, color: appRed) : null,
      ),
    );
  }
}
