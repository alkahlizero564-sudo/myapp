import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStorageService {
  static const _productsKey = 'products';
  static const _ordersKey = 'orders';

  Future<List<Product>> loadProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_productsKey) ?? [];
    return values.map(Product.fromJson).toList();
  }

  Future<void> saveProducts(List<Product> products) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _productsKey,
      products.map((product) => product.toJson()).toList(),
    );
  }

  Future<List<CustomerOrder>> loadOrders() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_ordersKey) ?? [];
    return values
        .map((value) =>
            CustomerOrder.fromMap(jsonDecode(value) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveOrders(List<CustomerOrder> orders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _ordersKey,
      orders.map((order) => jsonEncode(order.toMap())).toList(),
    );
  }
}
