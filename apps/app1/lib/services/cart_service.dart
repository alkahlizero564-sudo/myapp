import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const _cartKey = 'cart_items';
  static const _favoritesKey = 'favorite_items';

  Future<List<String>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cartKey) ?? <String>[];
  }

  Future<void> addToCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_cartKey) ?? <String>[];
    items.add(productId);
    await prefs.setStringList(_cartKey, items);
  }

  Future<void> removeFromCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_cartKey) ?? <String>[];
    items.remove(productId);
    await prefs.setStringList(_cartKey, items);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? <String>[];
  }

  Future<void> toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_favoritesKey) ?? <String>[];
    if (items.contains(productId)) {
      items.remove(productId);
    } else {
      items.add(productId);
    }
    await prefs.setStringList(_favoritesKey, items);
  }

  Future<void> saveProfile(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
  }

  Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('profile_name') ?? 'زائر',
      'email': prefs.getString('profile_email') ?? 'سجل دخولك للاستفادة من جميع المزايا',
    };
  }
}
