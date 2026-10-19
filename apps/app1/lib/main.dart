import 'package:flutter/material.dart';

import 'models/product.dart';
import 'services/cart_service.dart';

void main() {
  runApp(const SmartPhonesApp());
}

class SmartPhonesApp extends StatelessWidget {
  const SmartPhonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نوفا فون',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B4FE9),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
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
            borderSide: const BorderSide(color: Color(0xFF5B4FE9)),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final CartService _cartService = CartService();
  List<String> _cartItems = <String>[];
  List<String> _favorites = <String>[];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final cart = await _cartService.getCartItems();
    final favorites = await _cartService.getFavorites();
    if (!mounted) return;
    setState(() {
      _cartItems = cart;
      _favorites = favorites;
    });
  }

  Future<void> _toggleFavorite(Product product) async {
    await _cartService.toggleFavorite(product.id);
    await _loadSavedData();
  }

  Future<void> _addToCart(Product product) async {
    await _cartService.addToCart(product.id);
    await _loadSavedData();
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

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          isFavorite: _favorites.contains(product.id),
          onFavorite: () => _toggleFavorite(product),
          onAddToCart: () => _addToCart(product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        favorites: _favorites,
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
        onProductTap: _openProduct,
        onSeeAll: () => setState(() => _selectedIndex = 1),
      ),
      CatalogScreen(
        favorites: _favorites,
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
        onProductTap: _openProduct,
      ),
      CartScreen(
        cartIds: _cartItems,
        onRemove: (product) async {
          await _cartService.removeFromCart(product.id);
          await _loadSavedData();
        },
        onClear: () async {
          await _cartService.clearCart();
          await _loadSavedData();
        },
      ),
      FavoritesScreen(
        favorites: _favorites,
        onFavorite: _toggleFavorite,
        onAddToCart: _addToCart,
        onProductTap: _openProduct,
      ),
      ProfileScreen(cartCount: _cartItems.length),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8E5FF),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'المتجر',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'السلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<String> favorites;
  final Future<void> Function(Product) onFavorite;
  final Future<void> Function(Product) onAddToCart;
  final void Function(Product) onProductTap;
  final VoidCallback onSeeAll;

  const HomeScreen({
    super.key,
    required this.favorites,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onProductTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً بك في',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'نوفا فون',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF22213A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF34324D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن هاتفك المفضل...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Container(
                height: 175,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B4FE9), Color(0xFF8175F4)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: -15,
                      bottom: -20,
                      child: Opacity(
                        opacity: .18,
                        child: Icon(
                          Icons.phone_android_rounded,
                          size: 190,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خصم يصل إلى 30%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'على أحدث الهواتف الذكية',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Spacer(),
                          Chip(
                            label: Text(
                              'تسوق الآن',
                              style: TextStyle(color: Color(0xFF5B4FE9)),
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الأكثر مبيعاً',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 330,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, index) {
                    final product = products[index];
                    return SizedBox(
                      width: 205,
                      child: ProductCard(
                        product: product,
                        isFavorite: favorites.contains(product.id),
                        onFavorite: () => onFavorite(product),
                        onAddToCart: () => onAddToCart(product),
                        onTap: () => onProductTap(product),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  final List<String> favorites;
  final Future<void> Function(Product) onFavorite;
  final Future<void> Function(Product) onAddToCart;
  final void Function(Product) onProductTap;

  const CatalogScreen({
    super.key,
    required this.favorites,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onProductTap,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  String selectedBrand = 'الكل';

  @override
  Widget build(BuildContext context) {
    final brands = ['الكل', 'Apple', 'Samsung', 'Google', 'Xiaomi', 'OnePlus'];
    final filtered = products.where((product) {
      final matchesQuery = product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.brand.toLowerCase().contains(query.toLowerCase());
      final matchesBrand =
          selectedBrand == 'الكل' || product.brand == selectedBrand;
      return matchesQuery && matchesBrand;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'متجر الهواتف',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو العلامة التجارية',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 55,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final brand = brands[index];
                  return ChoiceChip(
                    label: Text(brand),
                    selected: selectedBrand == brand,
                    onSelected: (_) => setState(() => selectedBrand = brand),
                    selectedColor: const Color(0xFF5B4FE9),
                    labelStyle: TextStyle(
                      color: selectedBrand == brand ? Colors.white : null,
                    ),
                  );
                },
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('لم نجد منتجات مطابقة لبحثك')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, index) {
                    final product = filtered[index];
                    return ProductCard(
                      product: product,
                      isFavorite: widget.favorites.contains(product.id),
                      onFavorite: () => widget.onFavorite(product),
                      onAddToCart: () => widget.onAddToCart(product),
                      onTap: () => widget.onProductTap(product),
                    );
                  },
                  childCount: filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .65,
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
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Color(int.parse(product.color)),
                    child: Center(
                      child: Text(product.emoji, style: const TextStyle(fontSize: 86)),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: InkWell(
                      onTap: onFavorite,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (product.isNew)
                    Positioned(
                      top: 10,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4FE9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'جديد',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: Color(0xFF7067D8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 15, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(fontSize: 12),
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
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF25233D),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B4FE9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 17,
                              color: Colors.white,
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
  final Product product;
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
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              color: isFavorite ? Colors.red : null,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton.icon(
              onPressed: () {
                onAddToCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة المنتج إلى السلة'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('أضف إلى السلة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF5B4FE9),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Container(
              height: 290,
              decoration: BoxDecoration(
                color: Color(int.parse(product.color)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(product.emoji, style: const TextStyle(fontSize: 145)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.brand,
                    style: const TextStyle(
                      color: Color(0xFF5B4FE9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${product.rating} (${product.reviews} تقييم)'),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              product.name,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} ر.س',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B4FE9),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${product.oldPrice.toStringAsFixed(0)} ر.س',
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'خصم ${product.discount}%',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'عن المنتج',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.7,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'المواصفات الرئيسية',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...product.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF5B4FE9),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(feature),
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

class CartScreen extends StatelessWidget {
  final List<String> cartIds;
  final Future<void> Function(Product) onRemove;
  final Future<void> Function() onClear;

  const CartScreen({
    super.key,
    required this.cartIds,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cartProducts = cartIds
        .map((id) => products.where((product) => product.id == id).firstOrNull)
        .whereType<Product>()
        .toList();
    final total = cartProducts.fold<double>(
      0,
      (sum, product) => sum + product.price,
    );

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'سلة التسوق',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                if (cartProducts.isNotEmpty)
                  TextButton(onPressed: onClear, child: const Text('إفراغ السلة')),
              ],
            ),
          ),
          if (cartProducts.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'السلة فارغة',
                subtitle: 'أضف بعض المنتجات الرائعة لتظهر هنا',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cartProducts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final product = cartProducts[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Color(int.parse(product.color)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(product.emoji, style: const TextStyle(fontSize: 40)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${product.price.toStringAsFixed(0)} ر.س',
                                style: const TextStyle(
                                  color: Color(0xFF5B4FE9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemove(product),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (cartProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('الإجمالي')),
                      Text(
                        '${total.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _showCheckout(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF5B4FE9),
                      ),
                      child: const Text('إتمام الطلب'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            const Text(
              'طلبك جاهز للتأكيد',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('سيتم التواصل معك لتأكيد العنوان وموعد التوصيل.'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلبك بنجاح'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('تأكيد الطلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<String> favorites;
  final Future<void> Function(Product) onFavorite;
  final Future<void> Function(Product) onAddToCart;
  final void Function(Product) onProductTap;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onFavorite,
    required this.onAddToCart,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = products
        .where((product) => favorites.contains(product.id))
        .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Text(
              'المفضلة',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          if (favoriteProducts.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.favorite_border,
                title: 'لا توجد مفضلات بعد',
                subtitle: 'اضغط على القلب لحفظ المنتجات التي تعجبك',
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: favoriteProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .65,
                ),
                itemBuilder: (_, index) {
                  final product = favoriteProducts[index];
                  return ProductCard(
                    product: product,
                    isFavorite: true,
                    onFavorite: () => onFavorite(product),
                    onAddToCart: () => onAddToCart(product),
                    onTap: () => onProductTap(product),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final int cartCount;

  const ProfileScreen({super.key, required this.cartCount});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CartService _service = CartService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _service.getProfile();
    _nameController.text = profile['name'] == 'زائر' ? '' : profile['name']!;
    _emailController.text =
        profile['email'] == 'سجل دخولك للاستفادة من جميع المزايا'
            ? ''
            : profile['email']!;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    await _service.saveProfile(_nameController.text.trim(), _emailController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ بياناتك بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          const Text(
            'حسابي',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFE8E5FF),
              child: const Icon(Icons.person, size: 46, color: Color(0xFF5B4FE9)),
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color(0xFF5B4FE9),
              ),
              child: const Text('حفظ البيانات'),
            ),
          ),
          const SizedBox(height: 26),
          const ProfileOption(
            icon: Icons.receipt_long_outlined,
            title: 'طلباتي',
            subtitle: 'تابع حالة طلباتك السابقة',
          ),
          ProfileOption(
            icon: Icons.shopping_bag_outlined,
            title: 'السلة',
            subtitle: '${widget.cartCount} منتجات في السلة',
          ),
          const ProfileOption(
            icon: Icons.location_on_outlined,
            title: 'عناوين التوصيل',
            subtitle: 'أضف أو عدّل عناوينك',
          ),
          const ProfileOption(
            icon: Icons.help_outline,
            title: 'المساعدة والدعم',
            subtitle: 'نحن هنا لمساعدتك',
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEDEBFF),
        child: Icon(icon, color: const Color(0xFF5B4FE9)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 78, color: const Color(0xFFB8B4DD)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
