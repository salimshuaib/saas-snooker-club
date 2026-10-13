import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/utils/debouncer.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/inventory/presentation/widgets/inventory_stats_card.dart';
import 'package:snooker_club/features/inventory/presentation/widgets/inventory_product_card.dart';
import 'package:snooker_club/features/inventory/presentation/widgets/add_product_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final stats = ref.watch(inventoryStatsProvider);
    final quickSalesTotal = ref.watch(todaysQuickSalesTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.inventory),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              context.push('/inventory/inventory-history');
            },
            icon: const Icon(Icons.history),
            tooltip: 'Inventory History',
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          final categories = {
            'All',
            'Drinks',
            'Food',
            'Snacks',
            'Cigarettes',
            'Other',
            ...items.map((e) => e.category),
          };

          final filteredItems = items.where((item) {
            final matchesSearch = item.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesCategory =
                _selectedCategory == 'All' ||
                item.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── Stats ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InventoryStatsCard(
                          title: 'Total Stock',
                          value: '${stats['totalStockItems']}',
                          icon: Icons.inventory_2,
                          color: AppColors.primary,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: InventoryStatsCard(
                          title: 'Low/Out',
                          value:
                              '${stats['lowStockCount']}/${stats['outOfStockCount']}',
                          icon: Icons.warning,
                          color: stats['outOfStockCount'] > 0
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: InventoryStatsCard(
                          title: 'Quick Sales',
                          value: '₹${quickSalesTotal.toStringAsFixed(0)}',
                          icon: Icons.payments,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search & Filters ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppTextField(
                    hint: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (val) => _debouncer.run(
                      () => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(16)),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) =>
                              setState(() => _selectedCategory = cat),
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(16)),

              // ── Products List ──
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No products found',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InventoryProductCard(item: filteredItems[index]),
                      );
                    }, childCount: filteredItems.length),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            useRootNavigator: true,
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddProductSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
