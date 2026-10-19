import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';

class ProductsScreen extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onTogglePublished;
  final ValueChanged<Product> onDelete;
  final VoidCallback onAdd;

  const ProductsScreen({
    super.key,
    required this.products,
    required this.onTogglePublished,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأصناف'),
        actions: [
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'إضافة صنف',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف'),
      ),
      body: products.isEmpty
          ? _EmptyState(onAdd: onAdd)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(
                  product: product,
                  onTogglePublished: () => onTogglePublished(product),
                  onDelete: () => onDelete(product),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 90,
              color: Theme.of(context).colorScheme.primary.withOpacity(.45),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد أصناف حتى الآن',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف أصناف متجرك لتظهر في التطبيق الأول',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول صنف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTogglePublished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final image = product.imageBase64 == null
        ? null
        : Image.memory(
            base64Decode(product.imageBase64!),
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: image ??
                  Icon(
                    Icons.fastfood_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${product.price.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') onTogglePublished();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    product.isPublished ? 'إخفاء من التطبيق الأول' : 'نشر في التطبيق الأول',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف الصنف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر اختيار الصورة')),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final product = Product(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      category: _categoryController.text.trim(),
      imageBase64: _imageBytes == null ? null : base64Encode(_imageBytes!),
      isPublished: true,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة صنف جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                  image: _imageBytes == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(_imageBytes!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 54,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          const Text('إرفاق صورة للصنف'),
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircleAvatar(
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.edit),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الصنف',
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'أدخل اسم الصنف' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
                hintText: 'مثال: وجبات، مشروبات، حلويات',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'أدخل التصنيف' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر',
                suffixText: 'ر.س',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final price = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (price == null || price < 0) return 'أدخل سعراً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف الصنف',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish),
              label: const Text('حفظ ونشر الصنف'),
            ),
          ],
        ),
      ),
    );
  }
}
