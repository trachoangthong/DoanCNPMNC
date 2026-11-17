class ProductReview {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final String userEmail;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ProductReview({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.userEmail,
    required this.userName,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, Object?> json) {
    return ProductReview(
      id: json['id'] as int?,
      orderId: json['orderId'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      rating: json['rating'] as int,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
