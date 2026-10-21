import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';

class LocalStorage {
  static const _productsKey = 'products';
  static const _ordersKey = 'orders';

  final SharedPreferences _preferences;

  LocalStorage._(this._preferences);

  static Future<LocalStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStorage._(preferences);
  }

  Future<List<Product>> getProducts() async {
    final values = _preferences.getStringList(_productsKey) ?? [];

    return values
        .map((value) {
          try {
            return Product.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Product>()
        .toList();
  }

  Future<void> saveProducts(List<Product> products) async {
    await _preferences.setStringList(
      _productsKey,
      products.map((product) => jsonEncode(product.toJson())).toList(),
    );
  }

  Future<void> addProduct(Product product) async {
    final products = await getProducts();
    products.insert(0, product);
    await saveProducts(products);
  }

  Future<void> removeProduct(String productId) async {
    final products = await getProducts();
    products.removeWhere((product) => product.id == productId);
    await saveProducts(products);
  }

  Future<void> updateProduct(Product product) async {
    final products = await getProducts();
    final index = products.indexWhere((item) => item.id == product.id);

    if (index >= 0) {
      products[index] = product;
      await saveProducts(products);
    }
  }

  Future<List<Order>> getOrders() async {
    final values = _preferences.getStringList(_ordersKey) ?? [];

    return values
        .map((value) {
          try {
            return Order.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Order>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveOrders(List<Order> orders) async {
    await _preferences.setStringList(
      _ordersKey,
      orders.map((order) => jsonEncode(order.toJson())).toList(),
    );
  }

  Future<void> updateOrder(Order order) async {
    final orders = await getOrders();
    final index = orders.indexWhere((item) => item.id == order.id);

    if (index >= 0) {
      orders[index] = order;
      await saveOrders(orders);
    }
  }
}
