import 'package:flutter/material.dart';

import 'models/app_models.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'services/local_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF176B87);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المتجر',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      locale: const Locale('ar'),
      home: const AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _storage = LocalStorageService();
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  List<Product> _products = [];
  List<CustomerOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await _storage.loadProducts();
      final orders = await _storage.loadOrders();
      if (!mounted) return;
      setState(() {
        _products = products;
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل البيانات المحفوظة';
        _loading = false;
      });
    }
  }

  Future<void> _addProduct() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
    if (product == null) return;
    setState(() => _products = [product, ..._products]);
    await _storage.saveProducts(_products);
  }

  Future<void> _togglePublished(Product product) async {
    final updated = product.copyWith(isPublished: !product.isPublished);
    setState(() {
      _products = _products
          .map((item) => item.id == product.id ? updated : item)
          .toList();
    });
    await _storage.saveProducts(_products);
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: Text('هل تريد حذف "${product.name}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    setState(() => _products.removeWhere((item) => item.id == product.id));
    await _storage.saveProducts(_products);
  }

  Future<void> _changeOrderStatus(CustomerOrder order) async {
    setState(() {
      _orders = _orders
          .map((item) => item.id == order.id ? order : item)
          .toList();
    });
    await _storage.saveOrders(_orders);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: Text(_error!),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ProductsScreen(
              products: _products,
              onTogglePublished: _togglePublished,
              onDelete: _deleteProduct,
              onAdd: _addProduct,
            ),
            OrdersScreen(
              orders: _orders,
              onStatusChanged: _changeOrderStatus,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _products.isNotEmpty,
                label: Text('${_products.length}'),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              selectedIcon: const Icon(Icons.inventory_2),
              label: 'الأصناف',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _orders.isNotEmpty,
                label: Text('${_orders.length}'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'الطلبات',
            ),
          ],
        ),
      ),
    );
  }
}
