import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';

class InventoryStatusScreen extends ConsumerWidget {
  const InventoryStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Status & Alerts'),
        centerTitle: false,
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading inventory: $e')),
        data: (items) {
          final outOfStock = items
              .where((i) => i.currentStock == 0 && i.isActive)
              .toList();
          final lowStock = items
              .where(
                (i) => i.currentStock > 0 && i.currentStock <= 5 && i.isActive,
              )
              .toList();
          final disabled = items.where((i) => !i.isActive).toList();
          final activeOptimal = items
              .where((i) => i.currentStock > 5 && i.isActive)
              .toList();

          final hasAlerts =
              outOfStock.isNotEmpty ||
              lowStock.isNotEmpty ||
              disabled.isNotEmpty;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Status Banner ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: !hasAlerts
                          ? AppColors.available.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !hasAlerts
                            ? AppColors.available
                            : AppColors.warning,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !hasAlerts
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: !hasAlerts
                              ? AppColors.available
                              : AppColors.warning,
                          size: 36,
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !hasAlerts
                                    ? 'Everything looks good.'
                                    : 'Attention Required',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: !hasAlerts
                                      ? AppColors.available
                                      : AppColors.warning,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                !hasAlerts
                                    ? 'All active inventory products have healthy stock levels above threshold.'
                                    : '${outOfStock.length + lowStock.length + disabled.length} item(s) require review (Low stock, out of stock, or disabled).',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Out of Stock Section ───
              if (outOfStock.isNotEmpty) ...[
                _buildSectionHeader(
                  theme,
                  'Out of Stock Products',
                  Icons.remove_shopping_cart,
                  AppColors.error,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InventoryStatusTile(
                      item: outOfStock[index],
                      statusText: 'OUT OF STOCK',
                      statusColor: AppColors.error,
                    ),
                    childCount: outOfStock.length,
                  ),
                ),
              ],

              // ─── Low Stock Section ───
              if (lowStock.isNotEmpty) ...[
                _buildSectionHeader(
                  theme,
                  'Low Stock Products',
                  Icons.inventory,
                  AppColors.warning,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InventoryStatusTile(
                      item: lowStock[index],
                      statusText: 'LOW STOCK',
                      statusColor: AppColors.warning,
                    ),
                    childCount: lowStock.length,
                  ),
                ),
              ],

              // ─── Disabled Products Section ───
              if (disabled.isNotEmpty) ...[
                _buildSectionHeader(
                  theme,
                  'Disabled Products',
                  Icons.block,
                  theme.colorScheme.onSurfaceVariant,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InventoryStatusTile(
                      item: disabled[index],
                      statusText: 'DISABLED',
                      statusColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    childCount: disabled.length,
                  ),
                ),
              ],

              // ─── Active Products Section ───
              if (activeOptimal.isNotEmpty) ...[
                _buildSectionHeader(
                  theme,
                  'Active Products (Healthy Stock)',
                  Icons.check_box,
                  AppColors.available,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InventoryStatusTile(
                      item: activeOptimal[index],
                      statusText: 'ACTIVE',
                      statusColor: AppColors.available,
                    ),
                    childCount: activeOptimal.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: Gap(32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const Gap(8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryStatusTile extends StatelessWidget {
  final InventoryItem item;
  final String statusText;
  final Color statusColor;

  const _InventoryStatusTile({
    required this.item,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push('/inventory/inventory-details', extra: item);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Text(
                        'Category: ${item.category} • Current Qty: ${item.currentStock}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Gap(8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
