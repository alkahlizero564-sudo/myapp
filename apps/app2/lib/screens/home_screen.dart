import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/local_storage.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocalStorage storage;

  const HomeScreen({
    super.key,
    required this.storage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isOnline = true;
  List<Product> _products = [];
  List<Order> _orders = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    _checkConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _onConnectivityChanged(result);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
    });
  }

  Future<void> _loadData() async {
    try {
      final products = await widget.storage.getProducts();
      final orders = await widget.storage.getOrders();

      if (!mounted) return;
      setState(() {
        _products = products;
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل البيانات المحفوظة')),
      );
    }
  }

  Future<void> _openAddProduct() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(storage: widget.storage),
      ),
    );

    if (added == true) {
      await _loadData();
    }
  }

  Future<void> _toggleProduct(Product product, bool isActive) async {
    final updated = product.copyWith(isActive: isActive);
    await widget.storage.updateProduct(updated);
    await _loadData();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الصنف'),
          content: Text('هل تريد حذف "${product.name}" نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.storage.removeProduct(product.id);
      await _loadData();
    }
  }

  Future<void> _changeOrderStatus(Order order, OrderStatus status) async {
    await widget.storage.updateOrder(order.copyWith(status: status));
    await _loadData();
  }

  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'الأصناف';
      case 2:
        return 'الطلبات';
      default:
        return 'الإعدادات';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  _isOnline ? 'متصل' : 'غير متصل',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? Colors.green.shade700 : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboard(),
                _buildProducts(),
                _buildOrders(),
                _buildSettings(),
              ],
            ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة صنف'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'الأصناف',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'الطلبات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final activeProducts = _products.where((item) => item.isActive).length;
    final newOrders =
        _orders.where((order) => order.status == OrderStatus.newOrder).length;
    final totalSales = _orders
        .where((order) => order.status == OrderStatus.completed)
        .fold<double>(0, (sum, order) => sum + order.total);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C4AB6), Color(0xFF9273D2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في لوحة الإدارة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'أدر أصنافك وتابع طلبات العملاء بسهولة',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard(
                title: 'الأصناف المنشورة',
                value: '$activeProducts',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF6C4AB6),
              ),
              _statCard(
                title: 'الطلبات الجديدة',
                value: '$newOrders',
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFFE47B39),
              ),
              _statCard(
                title: 'إجمالي الطلبات',
                value: '${_orders.length}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF299B80),
              ),
              _statCard(
                title: 'المبيعات المكتملة',
                value: '${totalSales.toStringAsFixed(0)} ر.س',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF3F7DD3),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'إجراءات سريعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _quickAction(
            icon: Icons.add_box_rounded,
            title: 'إضافة صنف جديد',
            subtitle: 'أضف صنفاً مع صورته وسعره',
            onTap: _openAddProduct,
          ),
          _quickAction(
            icon: Icons.receipt_long_rounded,
            title: 'عرض الطلبات',
            subtitle: 'تابع الطلبات القادمة من التطبيق الأول',
            onTap: () => setState(() => _selectedIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 25),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0ECFA),
          child: Icon(icon, color: const Color(0xFF6C4AB6)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      ),
    );
  }

  Widget _buildProducts() {
    if (_products.isEmpty) {
      return _emptyState(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد أصناف بعد',
        subtitle: 'ابدأ بإضافة أول صنف ليظهر في التطبيق الأول',
        buttonText: 'إضافة صنف',
        onPressed: _openAddProduct,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '${_products.length} أصناف محفوظة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ..._products.map(
            (product) => ProductCard(
              product: product,
              onActiveChanged: (value) => _toggleProduct(product, value),
              onDelete: () => _deleteProduct(product),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrders() {
    if (_orders.isEmpty) {
      return _emptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد طلبات حالياً',
        subtitle: 'ستظهر هنا الطلبات التي يرسلها العملاء من التطبيق الأول',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _orderCard(_orders[index]),
      ),
    );
  }

  Widget _orderCard(Order order) {
    final date =
        '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF0ECFA),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFF6C4AB6),
          ),
        ),
        title: Text(
          order.customerName.isEmpty ? 'عميل بدون اسم' : order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('طلب #${order.id.substring(order.id.length - 6)} • $date'),
        trailing: _statusChip(order.status),
        children: [
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18),
              const SizedBox(width: 8),
              Text(order.customerPhone.isEmpty
                  ? 'لا يوجد رقم هاتف'
                  : order.customerPhone),
            ],
          ),
          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(order.address)),
              ],
            ),
          ],
          const Divider(height: 24),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text('${item.productName} × ${item.quantity}')),
                  Text('${item.price.toStringAsFixed(2)} ر.س'),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${order.total.toStringAsFixed(2)} ر.س',
                style: const TextStyle(
                  color: Color(0xFF6C4AB6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<OrderStatus>(
            value: order.status,
            decoration: const InputDecoration(
              labelText: 'تحديث حالة الطلب',
              prefixIcon: Icon(Icons.update_rounded),
            ),
            items: OrderStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: (status) {
              if (status != null) {
                _changeOrderStatus(order, status);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    Color color;

    switch (status) {
      case OrderStatus.newOrder:
        color = const Color(0xFFE47B39);
        break;
      case OrderStatus.preparing:
        color = const Color(0xFF3F7DD3);
        break;
      case OrderStatus.completed:
        color = const Color(0xFF299B80);
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0ECFA),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFF6C4AB6),
                  ),
                ),
                title: const Text(
                  'إدارة المتجر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('تحكم في أصنافك وطلباتك'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wifi_rounded),
                title: const Text('حالة الاتصال'),
                trailing: Text(
                  _isOnline ? 'متصل بالإنترنت' : 'غير متصل',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: const Text('التخزين المحلي'),
                subtitle: const Text('يتم حفظ الأصناف والبيانات على الجهاز'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('عن التطبيق'),
            subtitle: const Text('تطبيق إدارة الأصناف والطلبات - الإصدار 1.0'),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF0ECFA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: const Color(0xFF6C4AB6),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
