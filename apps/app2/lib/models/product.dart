class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String? imageBase64;
  final bool isActive;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageBase64,
    required this.isActive,
    required this.createdAt,
  });

  Product copyWith({
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageBase64,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageBase64: imageBase64 ?? this.imageBase64,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageBase64': imageBase64,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      price: (json['price'] as num).toDouble(),
      imageBase64: json['imageBase64'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
