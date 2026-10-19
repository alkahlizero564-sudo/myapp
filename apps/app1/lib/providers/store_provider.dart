import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sample_data.dart';
import '../models/phone.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class StoreProvider extends ChangeNotifier {
  List<Phone> _phones = [];
  final Map<String, CartItem> _cart = {};
  final Set<String> _wishlistIds = {};
  List<CustomerOrder> _orders = [];

  String _searchQuery = '';
  String _selectedBrand = 'الكل';
  String _selectedSort = 'المقترحة';
  double _priceRange = 7000;

  bool _initialized = false;
  String? _appliedPromoCode;
  double _promoDiscountPercentage = 0.0;

  StoreProvider() {
    _init();
  }

  bool get initialized => _initialized;
  List<Phone> get phones => _phones;
  Map<String, CartItem> get cart => _cart;
  Set<String> get wishlistIds => _wishlistIds;
  List<CustomerOrder> get orders => _orders;

  String get searchQuery => _searchQuery;
  String get selectedBrand => _selectedBrand;
  String get selectedSort => _selectedSort;
  double get priceRange => _priceRange;
  String? get appliedPromoCode => _appliedPromoCode;

  List<String> get availableBrands {
    final brands = _phones.map((p) => p.brand).toSet().toList();
    brands.insert(0, 'الكل');
    return brands;
  }

  int get cartCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _cart.values.fold(0.0, (sum, item) => sum + item.total);

  double get discountAmount => subtotal * _promoDiscountPercentage;

  double get deliveryFee => subtotal > 3000 || subtotal == 0 ? 0.0 : 35.0;

  double get grandTotal {
    if (subtotal == 0) return 0;
    return subtotal - discountAmount + deliveryFee;
  }

  Future<void> _init() async {
    _phones = List.from(samplePhones);
    final prefs = await SharedPreferences.getInstance();

    // Wishlist loading
    final savedWishlist = prefs.getStringList('store_wishlist');
    if (savedWishlist != null) {
      _wishlistIds.addAll(savedWishlist);
    }

    // Orders loading
    final ordersJson = prefs.getString('store_orders');
    if (ordersJson != null) {
      try {
        final List decoded = jsonDecode(ordersJson);
        _orders = decoded.map((e) => CustomerOrder.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error parsing saved orders: $e');
      }
    }

    // Cart loading
    final cartJson = prefs.getString('store_cart');
    if (cartJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cartJson);
        decoded.forEach((key, val) {
          final phoneId = val['phoneId'];
          final phone = _phones.firstWhere(
            (p) => p.id == phoneId,
            orElse: () => _phones.first,
          );
          _cart[key] = CartItem.fromJson(val, phone);
        });
      } catch (e) {
        debugPrint('Error parsing saved cart: $e');
      }
    }

    _initialized = true;
    notifyListeners();
  }

  // Search and Filter
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  void setPriceRange(double maxPrice) {
    _priceRange = maxPrice;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedBrand = 'الكل';
    _selectedSort = 'المقترحة';
    _priceRange = 7000;
    notifyListeners();
  }

  List<Phone> get filteredPhones {
    var list = _phones.where((phone) {
      final matchesSearch = _searchQuery.isEmpty ||
          phone.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phone.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phone.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesBrand =
          _selectedBrand == 'الكل' || phone.brand == _selectedBrand;

      final matchesPrice = phone.basePrice <= _priceRange;

      return matchesSearch && matchesBrand && matchesPrice;
    }).toList();

    if (_selectedSort == 'الأقل سعراً') {
      list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    } else if (_selectedSort == 'الأعلى سعراً') {
      list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
    } else if (_selectedSort == 'الأعلى تقييماً') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'الأحدث') {
      list.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
    }

    return list;
  }

  // Wishlist Logic
  bool isFavorite(String phoneId) => _wishlistIds.contains(phoneId);

  Future<void> toggleFavorite(String phoneId) async {
    if (_wishlistIds.contains(phoneId)) {
      _wishlistIds.remove(phoneId);
    } else {
      _wishlistIds.add(phoneId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('store_wishlist', _wishlistIds.toList());
  }

  List<Phone> get favoritePhones =>
      _phones.where((p) => _wishlistIds.contains(p.id)).toList();

  // Cart Logic
  void addToCart({
    required Phone phone,
    required String selectedColor,
    required String selectedStorage,
    required double price,
    int quantity = 1,
  }) {
    final key = '${phone.id}_${selectedColor}_$selectedStorage';
    if (_cart.containsKey(key)) {
      _cart[key]!.quantity += quantity;
    } else {
      _cart[key] = CartItem(
        phone: phone,
        selectedColor: selectedColor,
        selectedStorage: selectedStorage,
        price: price,
        quantity: quantity,
      );
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String cartKey, int change) {
    if (!_cart.containsKey(cartKey)) return;
    final item = _cart[cartKey]!;
    item.quantity += change;
    if (item.quantity <= 0) {
      _cart.remove(cartKey);
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(String cartKey) {
    _cart.remove(cartKey);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _appliedPromoCode = null;
    _promoDiscountPercentage = 0.0;
    _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartMap = _cart.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString('store_cart', jsonEncode(cartMap));
  }

  // Promo Code
  bool applyPromoCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'SMART10' || cleanCode == 'خصم10') {
      _appliedPromoCode = cleanCode;
      _promoDiscountPercentage = 0.10;
      notifyListeners();
      return true;
    } else if (cleanCode == 'VIP15') {
      _appliedPromoCode = cleanCode;
      _promoDiscountPercentage = 0.15;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _appliedPromoCode = null;
    _promoDiscountPercentage = 0.0;
    notifyListeners();
  }

  // Checkout and Orders
  Future<bool> placeOrder({
    required String recipientName,
    required String address,
    required String phone,
    required String paymentMethod,
  }) async {
    if (_cart.isEmpty) return false;

    final orderItems = _cart.values.map((c) {
      return OrderItem(
        phoneName: c.phone.name,
        brand: c.phone.brand,
        color: c.selectedColor,
        storage: c.selectedStorage,
        price: c.price,
        quantity: c.quantity,
        imageUrl: c.phone.images.isNotEmpty ? c.phone.images.first : '',
      );
    }).toList();

    final order = CustomerOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      dateTime: DateTime.now(),
      items: orderItems,
      subtotal: subtotal,
      discount: discountAmount,
      deliveryFee: deliveryFee,
      total: grandTotal,
      recipientName: recipientName,
      address: address,
      phone: phone,
      paymentMethod: paymentMethod,
    );

    _orders.insert(0, order);
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('store_orders', ordersJson);

    clearCart();
    return true;
  }
}
