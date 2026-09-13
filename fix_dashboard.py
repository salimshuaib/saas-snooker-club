import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# We want to replace the SingleChildScrollView content inside body: SafeArea(...)
# But first, let's wrap the SingleChildScrollView in a LayoutBuilder.
# Actually, the entire body can be wrapped in a LayoutBuilder.

old_body = """      body: SafeArea(
        child: SingleChildScrollView("""

new_body = """      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return SingleChildScrollView("""

# Then we need to find the FinancialOverviewCard() and the two Rows of stats.
# The structure is:
# FinancialOverviewCard(),
# const Gap(16),
# Row(children:[Expanded(...Running Tables...), SizedBox(width:16), Expanded(...Available Tables...)]),
# const Gap(16),
# Row(children:[Expanded(...Quick Sales...), SizedBox(width:16), Expanded(...Inventory Alerts...)]),

# We'll dynamically construct the stats block based on isDesktop.
# First, let's locate the FinancialOverviewCard call:
financial_card_start = text.find('const FinancialOverviewCard(),')

# The stats block ends after the Quick Sales / Inventory Alerts row.
# Let's find: "const Gap(32),\n\n              // Navigation Grid"
nav_grid_start = text.find('const Gap(32)', financial_card_start)

if financial_card_start != -1 and nav_grid_start != -1:
    stats_old_code = text[financial_card_start:nav_grid_start]
    
    # We will replace it with:
    stats_new_code = """isDesktop 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 4,
                      child: FinancialOverviewCard(),
                    ),
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
                      )
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

    text = text.replace(stats_old_code, stats_new_code)
    text = text.replace(old_body, new_body)

    # We also need to close the LayoutBuilder block at the very end.
    # Look for the end of SingleChildScrollView...
    # It ends right before return Scaffold
    # The end of the build method:
    end_of_scaffold = text.rfind('    );\\n  }\\n}\\n\\nclass _BookingsDashboardCard')
    if end_of_scaffold == -1:
        # try another signature
        end_of_scaffold = text.rfind('    );\n  }\n}\n\nclass _BookingsDashboardCard')
    
    if end_of_scaffold != -1:
        # we need to close layout builder just before Scaffold ends? No, LayoutBuilder is INSIDE body: SafeArea().
        # Let's find the closing of SafeArea.
        # It's at the end of the Scaffold.
        # old text:
        #             ],
        #           ),
        #         ),
        #       ),
        #     );
        #   }
        # }
        
        replace_end = """            ],
          ),
        ),
      ),
    );
  }
}"""
        
        new_replace_end = """            ],
          ),
        );
        },
        ),
      ),
    );
  }
}"""
        text = text.replace(replace_end, new_replace_end)
        
        # Finally, let's fix the New Quick Sale button.
        # It's currently:
        #               SizedBox(
        #                 width: double.infinity,
        #                 child: ElevatedButton.icon(
        # ...
        qs_btn_start = text.find('SizedBox(\n                width: double.infinity,\n                child: ElevatedButton.icon(')
        if qs_btn_start == -1:
            qs_btn_start = text.find('SizedBox(') # too risky, let's just do regex
            
        text = re.sub(r'SizedBox\(\s*width: double\.infinity,\s*child: ElevatedButton\.icon', 
                      r'SizedBox(width: isDesktop ? 300 : double.infinity, child: ElevatedButton.icon', text)
                      
        # Also Quick Access grid
        # GridView.count(crossAxisCount: 2,
        text = re.sub(r'GridView\.count\(\s*crossAxisCount: 2,',
                      r'GridView.count(crossAxisCount: isDesktop ? 4 : 2,', text)
                      
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(text)
        print("SUCCESS")
    else:
        print("FAILED TO FIND SCAFFOLD END")
else:
    print("FAILED TO FIND STATS BLOCK")

