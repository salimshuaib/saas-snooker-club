import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/inventory/presentation/widgets/add_product_sheet.dart';
import 'package:snooker_club/features/inventory/presentation/widgets/add_stock_sheet.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final InventoryItem item;

  const ProductDetailsScreen({super.key, required this.item});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  // To keep UI reactive to changes, we should probably listen to the item from the stream
  // But for simplicity in this detail view, we rely on the item passed or find it from the stream.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Find the latest item data from the stream to stay updated

    // Find the latest item data from the stream to stay updated
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final currentItem =
        itemsAsync.asData?.value.firstWhere(
          (e) => e.id == widget.item.id,
          orElse: () => widget.item,
        ) ??
        widget.item;

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentItem.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentItem.category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (currentItem.floorName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 14,
                                    color: theme.colorScheme
                                        .onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentItem.floorName!,
                                    style: TextStyle(
                                      color: theme.colorScheme
                                          .onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(24),
                  if (currentItem.isFood) ...[
                    Row(
                      children: [
                        _StatColumn(
                          'Selling Price',
                          '₹${currentItem.sellingPrice.toStringAsFixed(0)}',
                        ),
                        _StatColumn(
                          'Availability',
                          currentItem.isAvailable ? 'Available' : 'Unavailable',
                        ),
                        _StatColumn(
                          'Total Sold',
                          '${currentItem.totalSold}',
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        _StatColumn(
                          'Status',
                          currentItem.isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        _StatColumn(
                          'Current Stock',
                          '${currentItem.currentStock}',
                        ),
                        _StatColumn(
                          'Selling Price',
                          '₹${currentItem.sellingPrice.toStringAsFixed(0)}',
                        ),
                        _StatColumn(
                          'Purchase Price',
                          '₹${currentItem.purchasePrice.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        _StatColumn(
                          'Total Purchased',
                          '${currentItem.totalPurchased}',
                        ),
                        _StatColumn('Total Sold', '${currentItem.totalSold}'),
                        _StatColumn(
                          'Status',
                          currentItem.isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Gap(24),

            // ── Actions ──
            if (currentItem.isFood) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available for Orders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: currentItem.isAvailable,
                      onChanged: (val) {
                        ref
                            .read(inventoryRepositoryProvider)
                            .toggleAvailability(currentItem.id, val);
                      },
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddStockSheet(item: currentItem),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Stock'),
                    ),
                  ),
                ],
              ),
              const Gap(12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        useRootNavigator: true,
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            AddProductSheet(initialItem: currentItem),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(
                      currentItem.isFood ? 'Edit Food Item' : 'Edit Product',
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDisable(context, currentItem),
                    icon: const Icon(Icons.block, color: AppColors.error),
                    label: const Text(
                      'Disable',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(32),

            if (!currentItem.isFood)
              Text(
                'To view complete stock history, go to Inventory History.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisable(BuildContext context, InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Product?'),
        content: Text(
          'Are you sure you want to disable ${item.name}? It will no longer appear in sales or inventory lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Future.delayed(const Duration(milliseconds: 400));
      await ref.read(inventoryRepositoryProvider).disableProduct(item.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
