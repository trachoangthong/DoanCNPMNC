class Product {
  final int? id;
  final String name;
  final String image;
  final double price;
  final String category;
  final String description;
  final double discount;
  final String specifications;
  final int availableQuantity;
  final double rating;
  final int reviewCount;
  final List<String> images;

  const Product({
    this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.description,
    this.discount = 0.0,
    this.specifications = "",
    this.availableQuantity = 10,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json["images"] != null) {
      if (json["images"] is String) {
        imagesList = (json["images"] as String).split(',').where((s) => s.isNotEmpty).toList();
      } else if (json["images"] is List) {
        imagesList = List<String>.from(json["images"]);
      }
    }
    
    return Product(
      id: json["id"],
      name: json["name"] ?? "",
      image: json["image"] ?? "",
      price: (json["price"] as num).toDouble(),
      category: json["category"] ?? "",
      description: json["description"] ?? "",
      discount: (json["discount"] as num?)?.toDouble() ?? 0.0,
      specifications: json["specifications"] ?? "",
      availableQuantity: json["availableQuantity"] ?? 10,
      rating: (json["rating"] as num?)?.toDouble() ?? 4.5,
      reviewCount: json["reviewCount"] ?? 0,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "price": price,
      "category": category,
      "description": description,
      "discount": discount,
      "specifications": specifications,
      "availableQuantity": availableQuantity,
      "rating": rating,
      "reviewCount": reviewCount,
      "images": images.join(','),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? image,
    double? price,
    String? category,
    String? description,
    double? discount,
    String? specifications,
    int? availableQuantity,
    double? rating,
    int? reviewCount,
    List<String>? images,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      specifications: specifications ?? this.specifications,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
    );
  }
}
