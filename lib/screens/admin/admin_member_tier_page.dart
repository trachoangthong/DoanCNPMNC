import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/member_tier.dart';
import '../../models/order.dart';
import '../../models/user_model.dart';
import '../../services/shop_provider.dart';

class AdminMemberTierPage extends StatelessWidget {
  const AdminMemberTierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Consumer<ShopProvider>(
      builder: (BuildContext context, ShopProvider shop, Widget? child) {
        final List<UserModel> members = shop.users
            .where((UserModel user) => user.role.toLowerCase() != 'admin')
            .toList();

        return RefreshIndicator(
          onRefresh: shop.refreshData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                color: const Color(0xfffff1f2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.workspace_premium,
                        color: appRed,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Hạng thành viên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${members.length} thành viên • Chỉ tính đơn đã giao',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Làm mới dữ liệu',
                        onPressed: shop.refreshData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('Chưa có thành viên.')),
                ),
              ...members.map((UserModel user) {
                final MemberTierSummary summary =
                    MemberTierSummary.fromOrders(
                      shop.orders
                          .where(
                            (OrderModel order) =>
                                order.userEmail?.trim().toLowerCase() ==
                                user.email.trim().toLowerCase(),
                          )
                          .toList(),
                    );

                return Card(
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundImage: user.avatar.isEmpty
                                  ? null
                                  : NetworkImage(user.avatar),
                              child: user.avatar.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.workspace_premium,
                                color: appRed,
                                size: 18,
                              ),
                              label: Text('Hạng ${summary.tier.name}'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Tổng chi tiêu đã giao'),
                            Text(
                              currency.format(summary.tier.totalSpent),
                              style: const TextStyle(
                                color: appRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${summary.completedOrderCount} đơn hàng đã giao',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
