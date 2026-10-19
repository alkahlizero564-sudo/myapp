import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/phone.dart';
import '../providers/store_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Phone phone;

  const ProductDetailScreen({super.key, required this.phone});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  late String _selectedColor;
  late PhoneVariant _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedColor =
        widget.phone.colors.isNotEmpty ? widget.phone.colors.first : 'الافتراضي';
    _selectedVariant = widget.phone.variants.isNotEmpty
        ? widget.phone.variants.first
        : const PhoneVariant(storage: '128 جيجابايت', price: 0);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0', 'ar_SA');
    final provider = context.watch<StoreProvider>();
    final isFav = provider.isFavorite(widget.phone.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.phone.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : null,
            ),
            onPressed: () => provider.toggleFavorite(widget.phone.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Previewer
            Container(
              height: 320,
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'phone_${widget.phone.id}',
                      child: Image.network(
                        widget.phone.images[_selectedImageIndex],
                        fit: BoxFit.contain,
                        height: 280,
                        errorBuilder: (ctx, _, __) => const Icon(
                          Icons.phone_android_rounded,
                          size: 96,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (widget.phone.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.phone.images.length,
                          (idx) => InkWell(
                            onTap: () => setState(() => _selectedImageIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _selectedImageIndex == idx ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _selectedImageIndex == idx
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.phone.brand,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.phone.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.phone.reviewsCount} تقييم)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Phone Title
                  Text(
                    widget.phone.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  // Price Display
                  Row(
                    children: [
                      Text(
                        currencyFormatter.format(_selectedVariant.price),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ر.س',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedVariant.originalPrice != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          currencyFormatter.format(_selectedVariant.originalPrice!),
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Storage Variant Selector
                  const Text(
                    'سعة التخزين',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.phone.variants.map((variant) {
                      final isSelected = _selectedVariant.storage == variant.storage;
                      return ChoiceChip(
                        label: Text(variant.storage),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedVariant = variant);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Colors Selector
                  const Text(
                    'اللون المتوفر',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.phone.colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return ChoiceChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedColor = color);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Description
                  const Text(
                    'وصف الهاتف',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.phone.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Technical Specs Table
                  const Text(
                    'المواصفات التقنية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSpecTable(context),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity buttons
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add to cart button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    'إضافة إلى السلة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    provider.addToCart(
                      phone: widget.phone,
                      selectedColor: _selectedColor,
                      selectedStorage: _selectedVariant.storage,
                      price: _selectedVariant.price,
                      quantity: _quantity,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة ${widget.phone.name} إلى السلة'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF0F766E),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecTable(BuildContext context) {
    final spec = widget.phone.specs;
    final rows = [
      {'label': 'الشاشة', 'value': spec.screen, 'icon': Icons.tv_rounded},
      {'label': 'المعالج', 'value': spec.processor, 'icon': Icons.memory_rounded},
      {'label': 'الذاكرة (RAM)', 'value': spec.ram, 'icon': Icons.sd_storage_rounded},
      {'label': 'الكاميرا', 'value': spec.camera, 'icon': Icons.camera_alt_rounded},
      {'label': 'البطارية والشحن', 'value': spec.battery, 'icon': Icons.battery_charging_full_rounded},
      {'label': 'نظام التشغيل', 'value': spec.os, 'icon': Icons.settings_applications_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r['icon'] as IconData, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    r['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    r['value'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
