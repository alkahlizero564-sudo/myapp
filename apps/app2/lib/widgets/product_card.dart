import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onActiveChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    if (product.imageBase64 != null && product.imageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(product.imageBase64!);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 86,
                height: 86,
                child: imageBytes != null
                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFF0ECFA),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: Color(0xFF6C4AB6),
                          size: 34,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      color: Color(0xFF6C4AB6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: product.isActive,
                  onChanged: onActiveChanged,
                  activeColor: const Color(0xFF6C4AB6),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'حذف الصنف',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
