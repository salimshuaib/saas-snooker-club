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
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _selectedFloorId;

  @override
  void initState() {
    super.initState();
    _selectedFloorId = ref.read(selectedFloorIdProvider);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final quickSalesTotal = ref.watch(todaysQuickSalesTotalProvider);
    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];

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

          // Floor-aware stats
          final floorScopedItems = items.where((i) {
            if (_selectedFloorId == null) return true;
            return i.floorId == _selectedFloorId;
          }).toList();
          final stockItems = floorScopedItems.where((i) => !i.isFood).toList();
          final totalStockItems = stockItems.fold(0, (sum, i) => sum + i.currentStock);
          final lowStockCount = stockItems.where((i) => i.isLowStock).length;
          final outOfStockCount = stockItems.where((i) => i.isOutOfStock).length;

          final filteredItems = items.where((item) {
            final matchesSearch = item.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesCategory =
                _selectedCategory == 'All' ||
                item.category == _selectedCategory;
            final matchesFloor =
                _selectedFloorId == null || item.floorId == _selectedFloorId;
            return matchesSearch && matchesCategory && matchesFloor;
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
                          title: _selectedFloorId != null ? 'Floor Stock' : 'Total Stock',
                          value: '$totalStockItems',
                          icon: Icons.inventory_2,
                          color: AppColors.primary,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: InventoryStatsCard(
                          title: 'Low/Out',
                          value: '$lowStockCount/$outOfStockCount',
                          icon: Icons.warning,
                          color: outOfStockCount > 0
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

              // ── Floor Filter (If Multi-Floor Club) ──
              if (hasFloors && floors.length > 1) ...[
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        FilterChip(
                          avatar: Icon(
                            Icons.domain,
                            size: 16,
                            color: _selectedFloorId == null
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          label: const Text('All Floors'),
                          selected: _selectedFloorId == null,
                          onSelected: (_) {
                            setState(() => _selectedFloorId = null);
                            ref
                                .read(selectedFloorIdProvider.notifier)
                                .selectFloor(null);
                          },
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: _selectedFloorId == null
                                ? AppColors.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: _selectedFloorId == null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedFloorId == null
                                  ? AppColors.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        ...floors.map((floor) {
                          final isSelected = _selectedFloorId == floor.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: FilterChip(
                              avatar: Icon(
                                Icons.layers_outlined,
                                size: 16,
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              label: Text(floor.name),
                              selected: isSelected,
                              onSelected: (val) {
                                final newFloorId = val ? floor.id : null;
                                setState(() {
                                  _selectedFloorId = newFloorId;
                                });
                                ref
                                    .read(selectedFloorIdProvider.notifier)
                                    .selectFloor(newFloorId);
                              },
                              backgroundColor: theme.colorScheme.surface,
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
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
                        }),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Gap(12)),
              ],

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
            builder: (_) => AddProductSheet(
              initialFloorId: _selectedFloorId,
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
