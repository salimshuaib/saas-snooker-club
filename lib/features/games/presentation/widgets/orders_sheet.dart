import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/manual_game_charge_setup.dart';

/// Bottom sheet to add items (Drinks or Cigarettes) to a running game.
/// Returns the list of new/updated [GameOrder]s to be merged into the session.
class OrdersSheet extends ConsumerStatefulWidget {
  final List<String> players;
  final List<GameOrder> currentOrders;
  final List<ManualGameCharge>? currentManualGameCharges;
  final bool enableGamesTab;

  const OrdersSheet({
    super.key,
    required this.players,
    required this.currentOrders,
    this.currentManualGameCharges,
    this.enableGamesTab = false,
  });

  @override
  ConsumerState<OrdersSheet> createState() => _OrdersSheetState();
}

class _OrdersSheetState extends ConsumerState<OrdersSheet> {
  late List<GameOrder> _orders;
  late List<ManualGameCharge> _manualGameCharges;
  String? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.currentOrders);
    _manualGameCharges = List.from(widget.currentManualGameCharges ?? []);
    if (widget.players.isNotEmpty) _selectedPlayer = widget.players.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading products: $err')),
        data: (items) {
          final activeProducts = items.where((i) => i.isActive).toList();
          var categories = activeProducts.map((e) => e.category).toSet().toList();
          if (categories.isEmpty) {
            categories = ['All'];
          }
          if (widget.enableGamesTab) {
            categories.insert(0, 'Games');
          }

          return DefaultTabController(
            length: categories.length,
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Orders', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(AddItemsResult(_orders, _manualGameCharges)),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Player Selector
                if (widget.players.length > 1) ...[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _PlayerChip(
                          label: 'Anyone',
                          isSelected: _selectedPlayer == null,
                          onTap: () => setState(() => _selectedPlayer = null),
                        ),
                        ...widget.players.map(
                          (p) => _PlayerChip(
                            label: p,
                            isSelected: _selectedPlayer == p,
                            onTap: () => setState(() => _selectedPlayer = p),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                ],

                // Tab Bar
                TabBar(tabs: categories.map((c) => Tab(text: c)).toList()),

                // Product List
                Expanded(
                  child: TabBarView(
                    children: categories.map((category) {
                      if (category == 'Games') {
                        return ManualGamesListTab(onChargeAdded: (charge) { setState(() => _manualGameCharges.add(charge)); });
                      }
                      final products = activeProducts
                          .where((p) => p.category == category)
                          .toList();
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('No active items in this category'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductTile(
                            product: product,
                            orders: _orders,
                            playerName: _selectedPlayer,
                            onChanged: (updatedOrders) {
                              setState(() => _orders = updatedOrders);
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),

                // Current Orders Summary
                if (_orders.isNotEmpty || _manualGameCharges.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Orders',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.25,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...(_orders.map(
                                  (o) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${o.quantity}x ${o.productName}${o.playerName != null ? ' (${o.playerName})' : ''}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        Text(
                                          '₹${o.total.toStringAsFixed(0)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () {
                                            setState(() => _orders.remove(o));
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                                ...(_manualGameCharges.grouped().map(
                                  (group) {
                                    final g = group.charge;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${group.quantity}x ${g.tableName} - ${g.gameType.displayName}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                          Text(
                                            '₹${group.totalAmount.toStringAsFixed(0)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () {
                                              setState(() => _manualGameCharges.remove(group.originalCharges.last));
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                )),
                              ],
                            ),
                          ),
                        ),
                        const Gap(4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '₹${(_orders.fold<double>(0, (s, o) => s + o.total) + _manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount)).toStringAsFixed(0)}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final InventoryItem product;
  final List<GameOrder> orders;
  final String? playerName;
  final void Function(List<GameOrder>) onChanged;

  const _ProductTile({
    required this.product,
    required this.orders,
    required this.playerName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Find existing order for this product + player
    final existing = orders
        .where((o) => o.productId == product.id && o.playerName == playerName)
        .toList();
    final currentQty = existing.isEmpty ? 0 : existing.first.quantity;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          product.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            '₹${product.sellingPrice.toStringAsFixed(0)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  (product.currentStock > 5
                          ? AppColors.available
                          : AppColors.warning)
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stock: ${product.currentStock}',
              style: TextStyle(
                color: product.currentStock > 5
                    ? AppColors.available
                    : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      trailing: currentQty == 0
          ? FilledButton.tonal(
              onPressed: () => _addItem(context, 1),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _addItem(context, -1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$currentQty',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addItem(context, 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
      ),
    );
  }

  void _addItem(BuildContext context, int delta) {
    if (delta > 0) {
      final totalOrdered = orders
          .where((o) => o.productId == product.id)
          .fold<int>(0, (sum, o) => sum + o.quantity);
      if (totalOrdered + delta > product.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock available (Current stock: ${product.currentStock})',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final updated = List<GameOrder>.from(orders);
    final existingIndex = updated.indexWhere(
      (o) => o.productId == product.id && o.playerName == playerName,
    );

    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      final newQty = existing.quantity + delta;
      if (newQty <= 0) {
        updated.removeAt(existingIndex);
      } else {
        updated[existingIndex] = existing.copyWith(quantity: newQty);
      }
    } else if (delta > 0) {
      updated.add(
        GameOrder(
          id: '${product.id}_${playerName ?? 'all'}_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          category: product.category,
          playerName: playerName,
          quantity: 1,
          pricePerUnit: product.sellingPrice,
        ),
      );
    }
    onChanged(updated);
  }
}
