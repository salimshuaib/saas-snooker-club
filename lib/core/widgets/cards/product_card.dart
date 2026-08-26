import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Product display card for Inventory.
class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String price;
  final int stock;
  final bool isLowStock;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.isLowStock = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowStock
                ? Colors.orange.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall,
                  ),
                  const Gap(2),
                  Text(
                    category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  'Stock: $stock',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLowStock
                        ? Colors.orange
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isLowStock ? FontWeight.w600 : null,
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
