class Category {
  final int? id;
  final String name;
  final String image;
  final String description;

  Category({
    this.id,
    required this.name,
    required this.image,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
    };
  }
}
