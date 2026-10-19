import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPhonesStoreApp());
}

class SmartPhone {
  final int id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double oldPrice;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviews;
  final List<String> colors;
  final String storage;
  final String ram;
  final bool isNew;
  final bool isFeatured;

  const SmartPhone({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.colors,
    required this.storage,
    required this.ram,
    required this.isNew,
    required this.isFeatured,
  });

  int get discountPercentage {
    if (oldPrice <= price) return 0;
    return (((oldPrice - price) / oldPrice) * 100).round();
  }
}

const products = <SmartPhone>[
  SmartPhone(
    id: 1,
    name: 'آيفون 15 برو ماكس',
    brand: 'Apple',
    description:
        'هاتف آيفون 15 برو ماكس بتصميم التيتانيوم المذهل، شريحة A17 Pro، وكاميرا احترافية متطورة.',
    price: 4899,
    oldPrice: 5299,
    imageUrl:
        'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800',
    category: 'آيفون',
    rating: 4.9,
    reviews: 248,
    colors: ['التيتانيوم الطبيعي', 'الأسود', 'الأزرق', 'الأبيض'],
    storage: '256 جيجابايت',
    ram: '8 جيجابايت',
    isNew: true,
    isFeatured: true,
  ),
  SmartPhone(
    id: 2,
    name: 'سامسونج جالكسي S24 Ultra',
    brand: 'Samsung',
    description:
        'تجربة ذكاء اصطناعي متكاملة مع قلم S Pen، كاميرا بدقة 200 ميجابكسل وشاشة Dynamic AMOLED.',
    price: 3999,
    oldPrice: 4499,
    imageUrl:
        'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800',
    category: 'سامسونج',
    rating: 4.8,
    reviews: 186,
    colors: ['الرمادي', 'الأسود', 'البنفسجي'],
    storage: '512 جيجابايت',
    ram: '12 جيجابايت',
    isNew: true,
    isFeatured: true,
  ),
  SmartPhone(
    id: 3,
    name: 'جوجل بيكسل 9 برو',
    brand: 'Google',
    description:
        'تصوير استثنائي بفضل الذكاء الاصطناعي، شاشة Super Actua وتصميم أنيق بأداء سريع.',
    price: 3299,
    oldPrice: 3599,
    imageUrl:
        'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800',
    category: 'جوجل',
    rating: 4.7,
    reviews: 94,
    colors: ['البورسلين', 'البيج', 'الأسود'],
    storage: '256 جيجابايت',
    ram: '16 جيجابايت',
    isNew: true,
    isFeatured: false,
  ),
  SmartPhone(
    id: 4,
    name: 'شاومي 14 الترا',
    brand: 'Xiaomi',
    description:
        'كاميرا لايكا احترافية، معالج Snapdragon 8 Gen 3 وشحن فائق السرعة.',
    price: 2799,
    oldPrice: 3199,
    imageUrl:
        'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=800',
    category: 'شاومي',
    rating: 4.6,
    reviews: 76,
    colors: ['الأسود', 'الأبيض'],
    storage: '512 جيجابايت',
    ram: '16 جيجابايت',
    isNew: false,
    isFeatured: true,
  ),
  SmartPhone(
    id: 5,
    name: 'آيفون 15',
    brand: 'Apple',
    description:
        'تصميم أنيق بألوان زاهية، كاميرا رئيسية بدقة 48 ميجابكسل وشريحة A16 Bionic.',
    price: 2999,
    oldPrice: 3299,
    imageUrl:
        'https://images.unsplash.com/photo-1696446701796-da61225697cc?w=800',
    category: 'آيفون',
    rating: 4.8,
    reviews: 321,
    colors: ['الأزرق', 'الوردي', 'الأخضر', 'الأسود'],
    storage: '128 جيجابايت',
    ram: '6 جيجابايت',
    isNew: false,
    isFeatured: false,
  ),
  SmartPhone(
    id: 6,
    name: 'سامسونج جالكسي A55',
    brand: 'Samsung',
    description:
        'هاتف عملي متوازن مع شاشة Super AMOLED وبطارية تدوم طوال اليوم.',
    price: 1399,
    oldPrice: 1599,
    imageUrl:
        'https://images.unsplash.com/photo-1585060544812-6b45742d762f?w=800',
    category: 'سامسونج',
    rating: 4.5,
    reviews: 142,
    colors: ['الأزرق', 'البنفسجي', 'الأسود'],
    storage: '128 جيجابايت',
    ram: '8 جيجابايت',
    isNew: false,
    isFeatured: false,
  ),
];

class CartItem {
  final SmartPhone product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class LocalStore {
  static const cartKey = 'cart_products';
  static const favoritesKey = 'favorite_products';

  static Future<SharedPreferences> get _preferences async {
    return SharedPreferences.getInstance();
  }

  static Future<List<int>> readIds(String key) async {
    final preferences = await _preferences;
    return preferences.getStringList(key)?.map(int.parse).toList() ?? [];
  }

  static Future<void> saveIds(String key, List<int> ids) async {
    final preferences = await _preferences;
    await preferences.setStringList(
      key,
      ids.map((id) => id.toString()).toList(),
    );
  }
}

class SmartPhonesStoreApp extends StatelessWidget {
  const SmartPhonesStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سوقي للهواتف',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5367D9),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const StoreShell(),
    );
  }
}

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final List<CartItem> _cart = [];
  final Set<int> _favoriteIds = {};
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  final categories = const ['الكل', 'آيفون', 'سامسونج', 'جوجل', 'شاومي'];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    try {
      final cartIds = await LocalStore.readIds(LocalStore.cartKey);
      final favoriteIds = await LocalStore.readIds(LocalStore.favoritesKey);
      if (!mounted) return;
      setState(() {
        for (final id in cartIds) {
          final product = products.where((item) => item.id == id).firstOrNull;
          if (product != null) _cart.add(CartItem(product: product));
        }
        _favoriteIds.addAll(favoriteIds);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل بيانات المتجر. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _toggleFavorite(SmartPhone product) async {
    setState(() {
      if (_favoriteIds.contains(product.id)) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id);
      }
    });
    await LocalStore.saveIds(
      LocalStore.favoritesKey,
      _favoriteIds.toList(),
    );
  }

  Future<void> _addToCart(SmartPhone product) async {
    final existing = _cart.where((item) => item.product.id == product.id).firstOrNull;
    setState(() {
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
    await LocalStore.saveIds(
      LocalStore.cartKey,
      _cart.map((item) => item.product.id).toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت إضافة ${product.name} إلى السلة'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'عرض السلة',
          onPressed: () => setState(() => _selectedIndex = 2),
        ),
      ),
    );
  }

  Future<void> _removeFromCart(CartItem item) async {
    setState(() => _cart.remove(item));
    await LocalStore.saveIds(
      LocalStore.cartKey,
      _cart.map((cartItem) => cartItem.product.id).toList(),
    );
  }

  Future<void> _changeQuantity(CartItem item, int change) async {
    setState(() {
      item.quantity += change;
      if (item.quantity <= 0) _cart.remove(item);
    });
    await LocalStore.saveIds(
      LocalStore.cartKey,
      _cart.map((cartItem) => cartItem.product.id).toList(),
    );
  }

  List<SmartPhone> get _filteredProducts {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'الكل' ||
          product.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);

  void _openProduct(SmartPhone product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          isFavorite: _favoriteIds.contains(product.id),
          onFavorite: () => _toggleFavorite(product),
          onAddToCart: () => _addToCart(product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 60),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _loadLocalData();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screens = [
      _buildHomeScreen(),
      _buildFavoritesScreen(),
      _buildCartScreen(),
      const AccountScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _favoriteIds.isNotEmpty,
                label: Text('${_favoriteIds.length}'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: const Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _cart.isNotEmpty,
                label: Text('${_cart.length}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'السلة',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final featured = products.where((product) => product.isFeatured).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً بك في',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'سوقي للهواتف',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      Icons.notifications_none,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: TextField(
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن هاتفك المفضل',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF596DDD), Color(0xFF8E68D9)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'عروض حصرية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'خصومات تصل إلى 30% على أحدث الهواتف',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 15),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF596DDD),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCategory = 'الكل';
                                _searchQuery = '';
                              });
                            },
                            child: const Text('تسوق الآن'),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.smartphone,
                      color: Colors.white,
                      size: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الأقسام',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category == 'الكل'
                                  ? Icons.apps
                                  : Icons.phone_iphone,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_searchQuery.isEmpty && _selectedCategory == 'الكل')
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الأكثر مبيعاً',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedCategory = 'الكل'),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = _searchQuery.isEmpty &&
                          _selectedCategory == 'الكل'
                      ? featured
                      : _filteredProducts;
                  return ProductCard(
                    product: list[index],
                    isFavorite: _favoriteIds.contains(list[index].id),
                    onFavorite: () => _toggleFavorite(list[index]),
                    onTap: () => _openProduct(list[index]),
                    onAdd: () => _addToCart(list[index]),
                  );
                },
                childCount: (_searchQuery.isEmpty && _selectedCategory == 'الكل'
                        ? featured
                        : _filteredProducts)
                    .length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.66,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesScreen() {
    final favoriteProducts =
        products.where((product) => _favoriteIds.contains(product.id)).toList();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'المفضلة',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: favoriteProducts.isEmpty
                ? const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'لا توجد منتجات مفضلة',
                    subtitle: 'أضف الهواتف التي تعجبك إلى قائمة المفضلة',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: favoriteProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.66,
                    ),
                    itemBuilder: (context, index) {
                      final product = favoriteProducts[index];
                      return ProductCard(
                        product: product,
                        isFavorite: true,
                        onFavorite: () => _toggleFavorite(product),
                        onTap: () => _openProduct(product),
                        onAdd: () => _addToCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartScreen() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سلة التسوق',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                if (_cart.isNotEmpty)
                  Text(
                    '${_cart.length} منتجات',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'السلة فارغة',
                    subtitle: 'استكشف منتجاتنا وأضف ما يناسبك إلى السلة',
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _cart.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return CartItemCard(
                              item: item,
                              onIncrease: () => _changeQuantity(item, 1),
                              onDecrease: () => _changeQuantity(item, -1),
                              onRemove: () => _removeFromCart(item),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            SummaryRow(
                              title: 'المجموع الفرعي',
                              value: '${_subtotal.toStringAsFixed(0)} ر.س',
                            ),
                            const SummaryRow(
                              title: 'الشحن',
                              value: 'مجاني',
                              valueColor: Colors.green,
                            ),
                            const Divider(height: 25),
                            SummaryRow(
                              title: 'الإجمالي',
                              value: '${_subtotal.toStringAsFixed(0)} ر.س',
                              isTotal: true,
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        total: _subtotal,
                                        itemCount: _cart.length,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('إتمام الطلب'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final SmartPhone product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.smartphone, size: 58),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onFavorite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} ر.س',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  final SmartPhone product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل المنتج'),
          actions: [
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 330,
                width: double.infinity,
                child: Hero(
                  tag: 'product_${product.id}',
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.smartphone, size: 100),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          '${product.rating} (${product.reviews} تقييم)',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (product.oldPrice > product.price)
                          Text(
                            '${product.oldPrice.toStringAsFixed(0)} ر.س',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'الوصف',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.7,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'المواصفات',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SpecificationBox(
                          icon: Icons.sd_storage_outlined,
                          title: 'التخزين',
                          value: product.storage,
                        ),
                        const SizedBox(width: 10),
                        SpecificationBox(
                          icon: Icons.memory,
                          title: 'الذاكرة',
                          value: product.ram,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () {
                          onAddToCart();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('أضف إلى السلة'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpecificationBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SpecificationBox({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 25,
            ),
            const SizedBox(height: 7),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.product.imageUrl,
                width: 85,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 85,
                  height: 90,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.smartphone),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${item.product.price.toStringAsFixed(0)} ر.س',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityButton(icon: Icons.remove, onPressed: onDecrease),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      QuantityButton(icon: Icons.add, onPressed: onIncrease),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const QuantityButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const SummaryRow({
    super.key,
    required this.title,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (isTotal ? Theme.of(context).colorScheme.primary : null),
            fontSize: isTotal ? 19 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final double total;
  final int itemCount;

  const CheckoutScreen({
    super.key,
    required this.total,
    required this.itemCount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;
  String _paymentMethod = 'الدفع عند الاستلام';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إتمام الطلب')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'بيانات التوصيل',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'أدخل اسمك' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 9) {
                    return 'أدخل رقم جوال صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'عنوان التوصيل',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل عنوان التوصيل'
                    : null,
              ),
              const SizedBox(height: 25),
              const Text(
                'طريقة الدفع',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'الدفع عند الاستلام',
                      groupValue: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value!),
                      title: const Text('الدفع عند الاستلام'),
                      secondary: const Icon(Icons.payments_outlined),
                    ),
                    RadioListTile<String>(
                      value: 'بطاقة بنكية',
                      groupValue: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value!),
                      title: const Text('بطاقة بنكية'),
                      secondary: const Icon(Icons.credit_card_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SummaryRow(
                        title: 'عدد المنتجات',
                        value: '${widget.itemCount}',
                      ),
                      const SizedBox(height: 10),
                      SummaryRow(
                        title: 'الإجمالي',
                        value: '${widget.total.toStringAsFixed(0)} ر.س',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _submitOrder,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('تأكيد الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDF6E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 65,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'تم تأكيد طلبك بنجاح',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'شكراً لتسوقك معنا. سيتم تجهيز طلبك وإرساله قريباً.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    child: const Text('العودة إلى الرئيسية'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 15),
          const Text(
            'حسابي',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'زائر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('سجل الدخول لتجربة أفضل'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AccountOption(
            icon: Icons.receipt_long_outlined,
            title: 'طلباتي',
            onTap: () {},
          ),
          AccountOption(
            icon: Icons.location_on_outlined,
            title: 'عناوين التوصيل',
            onTap: () {},
          ),
          AccountOption(
            icon: Icons.support_agent,
            title: 'تواصل معنا',
            onTap: () {},
          ),
          AccountOption(
            icon: Icons.info_outline,
            title: 'عن التطبيق',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class AccountOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AccountOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
