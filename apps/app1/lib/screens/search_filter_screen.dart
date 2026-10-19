import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../widgets/phone_card.dart';

class SearchFilterScreen extends StatelessWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final results = provider.filteredPhones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث والتصفية', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'تصفية النتائج',
            onPressed: () => _openFilterModal(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة ضبط',
            onPressed: () => provider.resetFilters(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الهاتف أو الشركة أو المواصفات...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => provider.setSearchQuery(''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Active filter tags row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Chip(
                  label: Text('الشركة: ${provider.selectedBrand}'),
                  onDeleted: provider.selectedBrand != 'الكل'
                      ? () => provider.setBrand('الكل')
                      : null,
                ),
                const SizedBox(width: 6),
                Chip(
                  label: Text('الترتيب: ${provider.selectedSort}'),
                ),
                const SizedBox(width: 6),
                Chip(
                  label: Text('الحد الأقصى: ${provider.priceRange.toInt()} ر.س'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عدد النتائج: ${results.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results Grid
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لم يتم العثور على أي هاتف مطابق',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'جرب البحث باسم آخر أو تغيير معايير التصفية',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return PhoneCard(phone: results[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openFilterModal(BuildContext context, StoreProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'خيارات التصفية والفرز',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Brand selection
                  const Text('الشركة المصنعة', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: provider.availableBrands.map((b) {
                      final isSelected = provider.selectedBrand == b;
                      return ChoiceChip(
                        label: Text(b),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            provider.setBrand(b);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Sort Options
                  const Text('ترتيب حسب', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['المقترحة', 'الأقل سعراً', 'الأعلى سعراً', 'الأعلى تقييماً', 'الأحدث']
                        .map((sortOption) {
                      final isSelected = provider.selectedSort == sortOption;
                      return ChoiceChip(
                        label: Text(sortOption),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            provider.setSort(sortOption);
                            setModalState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Max Price Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('السعر الأقصى', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${provider.priceRange.toInt()} ر.س'),
                    ],
                  ),
                  Slider(
                    value: provider.priceRange,
                    min: 1500,
                    max: 7000,
                    divisions: 11,
                    label: '${provider.priceRange.toInt()} ر.س',
                    onChanged: (val) {
                      provider.setPriceRange(val);
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('تطبيق التصفية'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
