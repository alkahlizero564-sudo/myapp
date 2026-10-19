import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageBase64;
  final bool isPublished;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageBase64,
    required this.isPublished,
    required this.createdAt,
  });

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageBase64,
    bool? isPublished,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageBase64: imageBase64 ?? this.imageBase64,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageBase64': imageBase64,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String? ?? 'عام',
      imageBase64: map['imageBase64'] as String?,
      isPublished: map['isPublished'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Product.fromJson(String source) =>
      Product.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class CustomerOrder {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final List<OrderLine> items;
  final double total;
  final String status;
  final DateTime createdAt;

  CustomerOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  CustomerOrder copyWith({String? status}) {
    return CustomerOrder(
      id: id,
      customerName: customerName,
      phone: phone,
      address: address,
      items: items,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    return CustomerOrder(
      id: map['id'] as String,
      customerName: map['customerName'] as String? ?? 'عميل',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => OrderLine.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num? ?? 0).toDouble(),
      status: map['status'] as String? ?? 'جديد',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderLine {
  final String productName;
  final int quantity;
  final double price;

  OrderLine({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderLine.fromMap(Map<String, dynamic> map) {
    return OrderLine(
      productName: map['productName'] as String? ?? 'صنف',
      quantity: map['quantity'] as int? ?? 1,
      price: (map['price'] as num? ?? 0).toDouble(),
    );
  }
}
