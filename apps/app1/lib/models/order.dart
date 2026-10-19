class OrderItem {
  final String phoneName;
  final String brand;
  final String color;
  final String storage;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.phoneName,
    required this.brand,
    required this.color,
    required this.storage,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'phoneName': phoneName,
        'brand': brand,
        'color': color,
        'storage': storage,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        phoneName: json['phoneName'] ?? '',
        brand: json['brand'] ?? '',
        color: json['color'] ?? '',
        storage: json['storage'] ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] ?? 1,
        imageUrl: json['imageUrl'] ?? '',
      );
}

class CustomerOrder {
  final String id;
  final DateTime dateTime;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String recipientName;
  final String address;
  final String phone;
  final String paymentMethod;
  final String status;

  CustomerOrder({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.recipientName,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.status = 'قيد التجهيز',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'deliveryFee': deliveryFee,
        'total': total,
        'recipientName': recipientName,
        'address': address,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'status': status,
      };

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
        id: json['id'] ?? '',
        dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((item) => OrderItem.fromJson(item))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        recipientName: json['recipientName'] ?? '',
        address: json['address'] ?? '',
        phone: json['phone'] ?? '',
        paymentMethod: json['paymentMethod'] ?? 'الدفع عند الاستلام',
        status: json['status'] ?? 'قيد التجهيز',
      );
}
