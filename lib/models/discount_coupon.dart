class DiscountCoupon {
  final int? id;
  final String code;
  final double discountPercent;
  final DateTime expiresAt;
  final bool isActive;

  const DiscountCoupon({
    this.id,
    required this.code,
    required this.discountPercent,
    required this.expiresAt,
    this.isActive = true,
  });

  factory DiscountCoupon.fromJson(Map<String, dynamic> json) {
    return DiscountCoupon(
      id: json['id'] as int?,
      code: json['code'] as String? ?? '',
      discountPercent: (json['discountPercent'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isActive: (json['isActive'] as int? ?? 1) == 1,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'code': code.trim().toUpperCase(),
      'discountPercent': discountPercent,
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }
}
