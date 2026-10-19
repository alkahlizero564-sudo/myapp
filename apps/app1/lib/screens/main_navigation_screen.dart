import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import 'home_screen.dart';
import 'search_filter_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    final screens = [
      HomeScreen(
        onOpenSearch: () => _switchTab(1),
        onOpenCart: () => _switchTab(3),
      ),
      const SearchFilterScreen(),
      WishlistScreen(
        onContinueShopping: () => _switchTab(0),
      ),
      CartScreen(
        onContinueShopping: () => _switchTab(0),
      ),
      const OrdersScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'استكشاف',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.wishlistIds.isNotEmpty,
              label: Text('${provider.wishlistIds.length}'),
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: provider.wishlistIds.isNotEmpty,
              label: Text('${provider.wishlistIds.length}'),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'المفضلة',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.cartCount > 0,
              label: Text('${provider.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: provider.cartCount > 0,
              label: Text('${provider.cartCount}'),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'السلة',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.orders.isNotEmpty,
              label: Text('${provider.orders.length}'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: provider.orders.isNotEmpty,
              label: Text('${provider.orders.length}'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'طلباتي',
          ),
        ],
      ),
    );
  }
}
