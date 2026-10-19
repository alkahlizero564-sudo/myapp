import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'محمد عبدالله');
  final _phoneController = TextEditingController(text: '0501234567');
  final _addressController = TextEditingController(text: 'الرياض - حي الياسمين - شارع أنس بن مالك');
  String _selectedPaymentMethod = 'الدفع عند الاستلام';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<StoreProvider>();

    final success = await provider.placeOrder(
      recipientName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
              const SizedBox(height: 16),
              const Text(
                'تم تأكيد طلبك بنجاح!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم تجهيز هاتفك وشحنه إلى عنوانك بأسرع وقت.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back from checkout
                },
                child: const Text('تم'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final currencyFormatter = NumberFormat('#,##0', 'ar_SA');

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping address form
              const Text(
                'بيانات التوصيل والمستلم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الجوال',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'يرجى إدخال رقم الجوال' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'عنوان الشحن بالتفصيل (المدينة، الحي، الشارع)',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'يرجى إدخال العنوان' : null,
              ),

              const SizedBox(height: 24),

              // Payment options
              const Text(
                'طريقة الدفع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPaymentRadio(
                title: 'الدفع عند الاستلام',
                subtitle: 'ادفع نقداً أو بالبطاقة عند وصول المندوب',
                icon: Icons.payments_outlined,
                value: 'الدفع عند الاستلام',
              ),
              _buildPaymentRadio(
                title: 'بطاقة مدى / ائتمانية',
                subtitle: 'دفع آمن وفوري عبر البطاقة البنكية',
                icon: Icons.credit_card_rounded,
                value: 'بطاقة ائتمانية / مدى',
              ),
              _buildPaymentRadio(
                title: 'Apple Pay / STC Pay',
                subtitle: 'المحفظة الرقمية السريعة',
                icon: Icons.account_balance_wallet_outlined,
                value: 'محفظة إلكترونية',
              ),

              const SizedBox(height: 24),

              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص الفاتورة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الفرعي'),
                        Text('${currencyFormatter.format(provider.subtotal)} ر.س'),
                      ],
                    ),
                    if (provider.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الخصم', style: TextStyle(color: Colors.green)),
                          Text('- ${currencyFormatter.format(provider.discountAmount)} ر.س',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الشحن'),
                        Text(provider.deliveryFee == 0
                            ? 'مجاني'
                            : '${currencyFormatter.format(provider.deliveryFee)} ر.س'),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المبلغ الإجمالي',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${currencyFormatter.format(provider.grandTotal)} ر.س',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _handleCompleteOrder,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تأكيد الطلب الآن',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRadio({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == value
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: _selectedPaymentMethod == value ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (val) {
          if (val != null) setState(() => _selectedPaymentMethod = val);
        },
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
