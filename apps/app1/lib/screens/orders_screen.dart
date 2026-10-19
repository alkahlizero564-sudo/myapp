import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final orders = provider.orders;
    final currencyFormatter = NumberFormat('#,##0', 'ar_SA');
    final dateFormatter = DateFormat('yyyy/MM/dd - hh:mm a', 'ar_SA');

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد طلبات سابقة',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'عندما تكمل عملية شراء ستظهر تفاصيل وحالة طلبك هنا',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'طلب #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateFormatter.format(order.dateTime),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Divider(height: 20),

                        // Order Items summary
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.smartphone_rounded, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.phoneName} (${item.storage}) x${item.quantity}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${currencyFormatter.format(item.price * item.quantity)} ر.س',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'طريقة الدفع: ${order.paymentMethod}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                Text(
                                  'المستلم: ${order.recipientName}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('الإجمالي', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '${currencyFormatter.format(order.total)} ر.س',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
