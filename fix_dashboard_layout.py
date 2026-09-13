import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Wrap body with LayoutBuilder
body_pattern = r'body:\s*SafeArea\(\s*child:\s*SingleChildScrollView\('
body_replacement = r'''body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return SingleChildScrollView('''

text = re.sub(body_pattern, body_replacement, text)

# Fix New Quick Sale button
qs_btn_pattern = r'SizedBox\(\s*width:\s*double\.infinity,\s*child:\s*ElevatedButton\.icon\('
qs_btn_replacement = r'SizedBox(\n                width: isDesktop ? 300 : double.infinity,\n                child: ElevatedButton.icon('
text = re.sub(qs_btn_pattern, qs_btn_replacement, text)

# Let's locate the FinancialOverviewCard and the two stat rows.
# Since doing it all in one regex is hard, let's just do it manually.
start_idx = text.find('const FinancialOverviewCard(),')
end_idx = text.find('const Gap(32),', start_idx)

if start_idx != -1 and end_idx != -1:
    old_stats = text[start_idx:end_idx]
    new_stats = """isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 4, child: FinancialOverviewCard()),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final active = ref.watch(runningTablesCountProvider);
                                    return _StatCard(
                                      title: 'Running Tables',
                                      value: active.toString(),
                                      icon: Icons.table_restaurant,
                                      iconColor: theme.colorScheme.primary,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final available = ref.watch(availableTablesCountProvider);
                                    return _StatCard(
                                      title: 'Available Tables',
                                      value: available.toString(),
                                      icon: Icons.check_circle_outline,
                                      iconColor: AppColors.completed,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final count = ref.watch(todaysQuickSalesCountProvider);
                                    return _StatCard(
                                      title: 'Quick Sales',
                                      value: count.toString(),
                                      icon: Icons.shopping_cart,
                                      iconColor: AppColors.info,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, _) {
                                    final itemsAsync = ref.watch(inventoryItemsProvider);
                                    return _StatCard(
                                      title: 'Inventory Alerts',
                                      value: itemsAsync.when(
                                        data: (items) {
                                          final low = items.where((i) => i.currentStock <= i.lowStockThreshold).length;
                                          return low == 0 ? 'All good' : '$low Low Stock';
                                        },
                                        loading: () => '...',
                                        error: (_, __) => 'Error',
                                      ),
                                      icon: Icons.warning_amber,
                                      iconColor: AppColors.warning,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InventoryStatusScreen())),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    const FinancialOverviewCard(),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final active = ref.watch(runningTablesCountProvider);
                              return _StatCard(
                                title: 'Running Tables',
                                value: active.toString(),
                                icon: Icons.table_restaurant,
                                iconColor: theme.colorScheme.primary,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final available = ref.watch(availableTablesCountProvider);
                              return _StatCard(
                                title: 'Available Tables',
                                value: available.toString(),
                                icon: Icons.check_circle_outline,
                                iconColor: AppColors.completed,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final count = ref.watch(todaysQuickSalesCountProvider);
                              return _StatCard(
                                title: 'Quick Sales Today',
                                value: count.toString(),
                                icon: Icons.shopping_cart,
                                iconColor: AppColors.info,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final itemsAsync = ref.watch(inventoryItemsProvider);
                              return _StatCard(
                                title: 'Inventory Alerts',
                                value: itemsAsync.when(
                                  data: (items) {
                                    final low = items.where((i) => i.currentStock <= i.lowStockThreshold).length;
                                    return low == 0 ? 'All good' : '$low Low Stock';
                                  },
                                  loading: () => '...',
                                  error: (_, __) => 'Error',
                                ),
                                icon: Icons.warning_amber,
                                iconColor: AppColors.warning,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const InventoryStatusScreen())),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
"""
    text = text.replace(old_stats, new_stats)

# Close LayoutBuilder
# The scaffold ends with:
#             ],
#           ),
#         ),
#       ),
#     );
#   }
scaffold_end_pattern = r'(\s*\]\,\s*\)\,\s*\)\,\s*\)\,\s*\)\;\s*\}\s*\}\s*class _BookingsDashboardCard)'
scaffold_end_replacement = r'''
            ],
          ),
        );
      },
    ),
      ),
    );
  }
}
class _BookingsDashboardCard'''
text = re.sub(scaffold_end_pattern, scaffold_end_replacement, text)

# GridView crossAxisCount
grid_pattern = r'GridView\.count\(\s*crossAxisCount: 2,'
grid_replacement = r'GridView.count(crossAxisCount: isDesktop ? 4 : 2,'
text = re.sub(grid_pattern, grid_replacement, text)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
