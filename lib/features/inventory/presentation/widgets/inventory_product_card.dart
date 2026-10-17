import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';

class InventoryProductCard extends ConsumerWidget {
  final InventoryItem item;

  const InventoryProductCard({super.key, required this.item});

  Color _getStatusColor() {
    if (item.isFood) {
      return item.isAvailable ? AppColors.available : AppColors.error;
    }
    if (item.isOutOfStock) return AppColors.error;
    if (item.isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  String _getStatusText() {
    if (item.isFood) {
      return item.isAvailable ? 'Available' : 'Unavailable';
    }
    if (item.isOutOfStock) return 'Out of Stock';
    if (item.isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  IconData _getCategoryIcon() {
    if (item.isFood) return Icons.fastfood;
    if (item.category == 'Drinks') return Icons.local_drink;
    if (item.category == 'Snacks') return Icons.fastfood;
    return Icons.smoking_rooms;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: () {
        context.push('/inventory/inventory-details', extra: item);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${item.sellingPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    item.category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      if (item.isFood) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: item.isAvailable,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              ref
                                  .read(inventoryRepositoryProvider)
                                  .toggleAvailability(item.id, val);
                            },
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Stock: ${item.currentStock}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
