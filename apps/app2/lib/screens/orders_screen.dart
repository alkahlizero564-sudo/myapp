import 'package:flutter/material.dart';

import '../models/app_models.dart';

class OrdersScreen extends StatelessWidget {
  final List<CustomerOrder> orders;
  final ValueChanged<CustomerOrder> onStatusChanged;

  const OrdersScreen({
    super.key,
    required this.orders,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 88,
                      color: Theme.of(context).colorScheme.primary.withOpacity(.45),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'لا توجد طلبات حالياً',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر هنا الطلبات الواردة من التطبيق الأول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _OrderCard(
                  order: orders[index],
                  onStatusChanged: onStatusChanged,
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  final ValueChanged<CustomerOrder> onStatusChanged;

  const _OrderCard({
    required this.order,
    required this.onStatusChanged,
  });

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case 'مكتمل':
        return Colors.green;
      case 'ملغي':
        return Colors.red;
      case 'قيد التجهيز':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(.14),
          child: Icon(Icons.receipt_long, color: statusColor),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${order.items.length} أصناف • ${order.total.toStringAsFixed(2)} ر.س',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (status) => onStatusChanged(order.copyWith(status: status)),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'جديد', child: Text('جديد')),
            PopupMenuItem(value: 'قيد التجهيز', child: Text('قيد التجهيز')),
            PopupMenuItem(value: 'مكتمل', child: Text('مكتمل')),
            PopupMenuItem(value: 'ملغي', child: Text('ملغي')),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              label: Text(order.status),
              labelStyle: TextStyle(color: statusColor),
              backgroundColor: statusColor.withOpacity(.12),
            ),
          ),
          const Divider(),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(item.productName)),
                  Text('${item.quantity} × ${item.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          if (order.phone.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(order.phone),
            ),
          if (order.address.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(order.address),
            ),
        ],
      ),
    );
  }
}
