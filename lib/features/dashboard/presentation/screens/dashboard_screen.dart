import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_activity_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? 'Admin User';

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final clubAsync = ref.watch(clubProfileProvider);
    
    // Tables & Active Games
    final tables = ref.watch(resolvedTablesProvider);
    
    // Group tables dynamically
    final groupedTables = <String, List<TableModel>>{
      'Snooker': [],
      'Pool': [],
      'Console & PC': [],
    };
    
    for (final table in tables) {
      if (table.type == TableType.snooker) {
        groupedTables['Snooker']!.add(table);
      } else if (table.type == TableType.indianPool || table.type == TableType.americanPool) {
        groupedTables['Pool']!.add(table);
      } else {
        groupedTables['Console & PC']!.add(table);
      }
    }

    final activeCategories = groupedTables.entries.where((entry) => entry.value.isNotEmpty).toList();

    // Default Empty State
    if (activeCategories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            color: theme.colorScheme.onSurface,
            tooltip: 'Menu',
            onPressed: () => context.push(RouteNames.more),
          ),
          title: Text(clubAsync.value?.clubName ?? 'Game Activity'),
          actions: _buildAppBarActions(theme, employeeName),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_restaurant_outlined, size: 64, color: Colors.grey),
              const Gap(16),
              Text(
                'No tables or games added yet',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(16),
              FilledButton.icon(
                onPressed: () => context.push(RouteNames.settings),
                icon: const Icon(Icons.settings),
                label: const Text('Add your first resource from Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Dynamic Tabs State
    final categoriesKey = activeCategories.map((e) => e.key).join('-');
    
    return DefaultTabController(
      key: ValueKey(categoriesKey),
      length: activeCategories.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            color: theme.colorScheme.onSurface,
            tooltip: 'Menu',
            onPressed: () => context.push(RouteNames.more),
          ),
          title: Text(clubAsync.value?.clubName ?? 'Game Activity'),
          actions: _buildAppBarActions(theme, employeeName),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: activeCategories.map((e) => Tab(text: e.key)).toList(),
          ),
        ),
        body: TabBarView(
          children: activeCategories.map((entry) {
            final categoryName = entry.key;
            final categoryTables = entry.value;

            // Group tables by their TableType
            final Map<TableType, List<TableModel>> grouped = {};
            for (var t in categoryTables) {
              grouped.putIfAbsent(t.type, () => []).add(t);
            }
            
            // Sort by display name
            final sortedTypes = grouped.keys.toList()
              ..sort((a, b) => a.displayName.compareTo(b.displayName));

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  for (var type in sortedTypes) ...[
                    // Show header if category has multiple types or name doesn't match
                    if (sortedTypes.length > 1 || categoryName != type.displayName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          type.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final list = List<TableModel>.from(grouped[type]!);
                        final item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                        ref.read(gamesRepositoryProvider).updateTableOrders(list);
                      },
                      children: [
                        for (var table in grouped[type]!)
                          Container(
                            key: ValueKey(table.id),
                            child: _buildTableCard(table),
                          ),
                      ],
                    ),
                    const Gap(16),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    return Consumer(
      builder: (context, ref, _) {
        final activeGameAsync = ref.watch(activeGameProvider(table.id));
        return GameActivityCard(
          table: table,
          activeGame: activeGameAsync.value,
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(ThemeData theme, String employeeName) {
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            employeeName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, size: 16, color: Colors.white),
        ),
      ),
    ];
  }
}