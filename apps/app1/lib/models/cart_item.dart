import 'dart:convert';
import 'phone.dart';

class CartItem {
  final Phone phone;
  final String selectedColor;
  final String selectedStorage;
  final double price;
  int quantity;

  CartItem({
    required this.phone,
    required this.selectedColor,
    required this.selectedStorage,
    required this.price,
    this.quantity = 1,
  });

  String get uniqueKey => '${phone.id}_${selectedColor}_$selectedStorage';

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'phoneId': phone.id,
        'phoneName': phone.name,
        'phoneBrand': phone.brand,
        'phoneImage': phone.images.isNotEmpty ? phone.images.first : '',
        'selectedColor': selectedColor,
        'selectedStorage': selectedStorage,
        'price': price,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json, Phone phone) => CartItem(
        phone: phone,
        selectedColor: json['selectedColor'] ?? '',
        selectedStorage: json['selectedStorage'] ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] ?? 1,
      );
}
