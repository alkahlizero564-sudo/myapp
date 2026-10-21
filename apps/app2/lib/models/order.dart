enum OrderStatus {
  newOrder,
  preparing,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'جديد';
      case OrderStatus.preparing:
        return 'قيد التجهيز';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.newOrder,
    );
  }
}

class OrderItem {
  final String productName;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      items: items,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];

    return Order(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      items: rawItems
          .map((item) => OrderItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      total: (json['total'] as num? ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(
        json['status'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
