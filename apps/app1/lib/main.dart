import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AyPersonApp());
}

class AyPersonApp extends StatelessWidget {
  const AyPersonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ايا شخص عايز امل بلدي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF177245),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF177245),
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loggedIn = preferences.getBool('logged_in') ?? false;
      _loading = false;
    });
  }

  Future<void> _onLogin() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('logged_in', true);
    if (!mounted) return;
    setState(() => _loggedIn = true);
  }

  Future<void> _onLogout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('logged_in', false);
    if (!mounted) return;
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _loggedIn
        ? HomeScreen(onLogout: _onLogout)
        : AuthScreen(onLogin: _onLogin);
  }
}

class AuthScreen extends StatefulWidget {
  final Future<void> Function() onLogin;

  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final preferences = await SharedPreferences.getInstance();

    if (_isLogin) {
      final savedEmail = preferences.getString('user_email');
      final savedPassword = preferences.getString('user_password');

      if (savedEmail != _emailController.text.trim() ||
          savedPassword != _passwordController.text) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showMessage('البريد الإلكتروني أو كلمة المرور غير صحيحة');
        return;
      }
    } else {
      await preferences.setString(
        'user_name',
        _nameController.text.trim(),
      );
      await preferences.setString(
        'user_email',
        _emailController.text.trim(),
      );
      await preferences.setString(
        'user_password',
        _passwordController.text,
      );
    }

    await widget.onLogin();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Container(
                    height: 96,
                    width: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'ايا شخص عايز امل بلدي',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'منتجات بلدية بطعم أصيل وجودة مضمونة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 42),
                  Text(
                    _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'اكتب الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'اكتب بريدًا إلكترونيًا صحيحًا';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _obscurePassword = !_obscurePassword,
                          );
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'دخول' : 'إنشاء الحساب',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'ليس لديك حساب؟ أنشئ حسابًا الآن'
                          : 'لديك حساب بالفعل؟ سجل الدخول',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String unit;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.emoji,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'unit': unit,
      'emoji': emoji,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      emoji: json['emoji'] as String,
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
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class CustomerOrder {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final String status;

  const CustomerOrder({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
    };
  }

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<void> Function() onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _loading = true;
  String _userName = 'صديقنا';
  List<Product> _products = [];
  List<CustomerOrder> _orders = [];
  final Map<String, int> _cart = {};

  final List<Product> _defaultProducts = const [
    Product(
      id: 'p1',
      name: 'عسل بلدي طبيعي',
      description: 'عسل نحل طبيعي من أجود المزارع المحلية',
      category: 'منتجات غذائية',
      price: 85,
      unit: 'العبوة',
      emoji: '🍯',
    ),
    Product(
      id: 'p2',
      name: 'جبنة بلدية',
      description: 'جبنة طازجة مصنوعة بالطريقة التقليدية',
      category: 'ألبان',
      price: 45,
      unit: 'الكيلو',
      emoji: '🧀',
    ),
    Product(
      id: 'p3',
      name: 'زيت زيتون أصلي',
      description: 'زيت زيتون بكر ممتاز ومعصور على البارد',
      category: 'زيوت',
      price: 120,
      unit: 'اللتر',
      emoji: '🫒',
    ),
    Product(
      id: 'p4',
      name: 'تمر بلدي',
      description: 'تمر فاخر بطعم حلو وقوام طري',
      category: 'منتجات غذائية',
      price: 60,
      unit: 'الكيلو',
      emoji: '🌴',
    ),
    Product(
      id: 'p5',
      name: 'مربى التين',
      description: 'مربى منزلية من التين الطازج',
      category: 'منتجات غذائية',
      price: 35,
      unit: 'المرطبان',
      emoji: '🍓',
    ),
    Product(
      id: 'p6',
      name: 'خبز بلدي',
      description: 'خبز طازج يوميًا على الطريقة البلدية',
      category: 'مخبوزات',
      price: 15,
      unit: 'الربطة',
      emoji: '🥖',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final preferences = await SharedPreferences.getInstance();
    final productsJson = preferences.getString('products');
    final ordersJson = preferences.getString('orders');

    List<Product> products = _defaultProducts;
    if (productsJson != null) {
      try {
        products = (jsonDecode(productsJson) as List)
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        products = _defaultProducts;
      }
    } else {
      await preferences.setString(
        'products',
        jsonEncode(_defaultProducts.map((item) => item.toJson()).toList()),
      );
    }

    List<CustomerOrder> orders = [];
    if (ordersJson != null) {
      try {
        orders = (jsonDecode(ordersJson) as List)
            .map((item) => CustomerOrder.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        orders = [];
      }
    }

    if (!mounted) return;
    setState(() {
      _userName = preferences.getString('user_name') ?? 'صديقنا';
      _products = products;
      _orders = orders;
      _loading = false;
    });
  }

  Future<void> _saveOrders() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'orders',
      jsonEncode(_orders.map((order) => order.toJson()).toList()),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة ${product.name} إلى الطلب'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(Product product) {
    final quantity = _cart[product.id] ?? 0;
    setState(() {
      if (quantity <= 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = quantity - 1;
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => _products.first,
      );
      total += product.price * entry.value;
    }
    return total;
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    final items = <OrderItem>[];
    for (final entry in _cart.entries) {
      final product = _products.firstWhere((item) => item.id == entry.key);
      items.add(
        OrderItem(
          productName: product.name,
          quantity: entry.value,
          price: product.price,
        ),
      );
    }

    final order = CustomerOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      items: items,
      total: _cartTotal,
      status: 'قيد التجهيز',
    );

    setState(() {
      _orders = [order, ..._orders];
      _cart.clear();
      _selectedIndex = 1;
    });
    await _saveOrders();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلبك بنجاح')),
    );
  }

  Future<void> _showCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final cartProducts = _products
                  .where((product) => _cart.containsKey(product.id))
                  .toList();

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الطلب الحالي',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (cartProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'لم تضف أي أصناف بعد',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: cartProducts.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final product = cartProducts[index];
                              final quantity = _cart[product.id]!;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Text(
                                  product.emoji,
                                  style: const TextStyle(fontSize: 30),
                                ),
                                title: Text(product.name),
                                subtitle: Text(
                                  '${product.price.toStringAsFixed(0)} جنيه × $quantity',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _removeFromCart(product);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      onPressed: () {
                                        _addToCart(product);
                                        setModalState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الإجمالي',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_cartTotal.toStringAsFixed(0)} جنيه',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _cart.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _placeOrder();
                                },
                          child: const Text('تأكيد الطلب'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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

    final pages = [
      CatalogPage(
        products: _products,
        cart: _cart,
        onAdd: _addToCart,
        onOpenCart: _showCart,
        userName: _userName,
      ),
      OrdersPage(orders: _orders),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? 'الأصناف' : 'طلباتي'),
          centerTitle: false,
          actions: [
            if (_selectedIndex == 0)
              IconButton(
                tooltip: 'الطلب الحالي',
                onPressed: _showCart,
                icon: Badge(
                  isLabelVisible: _cart.isNotEmpty,
                  label: Text(
                    _cart.values
                        .fold<int>(0, (previous, current) => previous + current)
                        .toString(),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  widget.onLogout();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('تسجيل الخروج'),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'الأصناف',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'طلباتي',
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  final List<Product> products;
  final Map<String, int> cart;
  final String userName;
  final void Function(Product product) onAdd;
  final Future<void> Function() onOpenCart;

  const CatalogPage({
    super.key,
    required this.products,
    required this.cart,
    required this.onAdd,
    required this.onOpenCart,
    required this.userName,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  List<String> get _categories {
    final categories = widget.products.map((item) => item.category).toSet();
    return ['الكل', ...categories];
  }

  List<Product> get _filteredProducts {
    return widget.products.where((product) {
      final matchesCategory = _selectedCategory == 'الكل' ||
          product.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                'أهلاً يا ${widget.userName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF177245), Color(0xFF2F9B62)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خير بلدنا عندنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'اختار منتجاتك البلدية المفضلة وخليها توصلك لحد البيت',
                    style: TextStyle(color: Colors.white, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: const InputDecoration(
                  hintText: 'ابحث عن صنف معين',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: category == _selectedCategory,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
              ),
            ),
          ),
          if (_filteredProducts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('لا توجد أصناف مطابقة للبحث'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(
                      product: product,
                      quantity: widget.cart[product.id] ?? 0,
                      onAdd: () => widget.onAdd(product),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 53),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.price.toStringAsFixed(0)} جنيه',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'إضافة للطلب',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (quantity > 0)
              Text(
                'في الطلب: $quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  final List<CustomerOrder> orders;

  const OrdersPage({super.key, required this.orders});

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day/$month/${localDate.year} - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 76,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                'لا توجد طلبات حتى الآن',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابدأ بتصفح الأصناف وأضف منتجاتك المفضلة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final itemCount = order.items.fold<int>(
          0,
          (previous, item) => previous + item.quantity,
        );

        return Card(
          elevation: 0,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.receipt_long_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              'طلب رقم ${order.id.substring(order.id.length - 5)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatDate(order.date)}\n$itemCount أصناف',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${order.total.toStringAsFixed(0)} جنيه',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.status,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              ...order.items.map(
                (item) => ListTile(
                  dense: true,
                  title: Text(item.productName),
                  subtitle: Text('الكمية: ${item.quantity}'),
                  trailing: Text(
                    '${(item.price * item.quantity).toStringAsFixed(0)} جنيه',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
