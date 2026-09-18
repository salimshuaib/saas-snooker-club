import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_activity_card.dart';

class GameActivityScreen extends ConsumerWidget {
  const GameActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tablesAsync = ref.watch(resolvedTablesProvider);
    final club = ref.watch(clubProfileProvider).value;
    final clubName = club?.clubName ?? 'Loading...';

    final currentStaff = ref.watch(currentStaffProvider).value;

    String currentUserName = currentStaff?.name ?? 'Admin';
    if (currentStaff?.role == StaffRole.owner ||
        currentStaff == null ||
        currentUserName == 'Admin' ||
        currentUserName == 'Club Owner') {
      final oName = club?.ownerName;
      if (oName != null && oName.isNotEmpty) {
        currentUserName = oName;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.push(RouteNames.more),
        ),
        title: Text(
          clubName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  currentUserName,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (tablesAsync.isEmpty) {
            return Center(
              child: Text(
                'No tables configured.',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          final tables = tablesAsync;

          final snookerTables = tables
              .where((t) => t.type == TableType.snooker)
              .toList();
          final poolTables = tables
              .where(
                (t) =>
                    t.type == TableType.indianPool ||
                    t.type == TableType.americanPool,
              )
              .toList();
          final consoleTables = tables
              .where(
                (t) =>
                    t.type == TableType.ps5 ||
                    t.type == TableType.ps4 ||
                    t.type == TableType.pc ||
                    t.type == TableType.arcade,
              )
              .toList();

          final existingTypes = <String>[];
          if (snookerTables.isNotEmpty) existingTypes.add('Snooker');
          if (poolTables.isNotEmpty) existingTypes.add('Pool');
          if (consoleTables.isNotEmpty) existingTypes.add('Console & PC');

          final otherTables = tables
              .where(
                (t) =>
                    !snookerTables.contains(t) &&
                    !poolTables.contains(t) &&
                    !consoleTables.contains(t),
              )
              .toList();
          if (otherTables.isNotEmpty) existingTypes.add('Other');

          return DefaultTabController(
            length: existingTypes.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  dividerColor: theme.colorScheme.outlineVariant,
                  tabs: existingTypes.map((t) => Tab(text: t)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: existingTypes.map((type) {
                      List<TableModel> tabTables = [];
                      if (type == 'Snooker')
                        tabTables = snookerTables;
                      else if (type == 'Pool')
                        tabTables = poolTables;
                      else if (type == 'Console & PC')
                        tabTables = consoleTables;
                      else if (type == 'Other')
                        tabTables = otherTables;

                      final grouped = <TableType, List<TableModel>>{};
                      for (final t in tabTables) {
                        grouped.putIfAbsent(t.type, () => []).add(t);
                      }

                      final sortedKeys = grouped.keys.toList()
                        ..sort((a, b) => a.index.compareTo(b.index));

                      return ListView(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        children: [
                          for (int i = 0; i < sortedKeys.length; i++) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4,
                                bottom: 12,
                                top: i > 0 ? 8 : 0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    sortedKeys[i].displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  _StatusBadge(
                                    label: 'Running',
                                    count: tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).length,
                                    color: AppColors.running,
                                    onTap: () => _showTablesList(
                                      context,
                                      sortedKeys[i].displayName,
                                      'Running Games',
                                      tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(
                                    label: 'Available',
                                    count: tables.where((t) => t.status == TableStatus.available).length,
                                    color: AppColors.available,
                                    onTap: () => _showTablesList(
                                      context,
                                      sortedKeys[i].displayName,
                                      'Available Games',
                                      tables.where((t) => t.status == TableStatus.available).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isTabletOrDesktop = MediaQuery.sizeOf(context).width >= 600;
                                
                                if (isTabletOrDesktop) {
                                  int crossAxisCount = (constraints.maxWidth / 320).floor();
                                  if (crossAxisCount < 2) crossAxisCount = 2;
                                  
                                  final double spacing = 16.0;
                                  final double totalSpacing = spacing * (crossAxisCount - 1);
                                  final double cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: grouped[sortedKeys[i]]!.map(
                                      (t) => SizedBox(
                                        width: cardWidth,
                                        child: GameActivityCard(table: t),
                                      ),
                                    ).toList(),
                                  );
                                }
                                
                                return Column(
                                  children: grouped[sortedKeys[i]]!.map(
                                    (t) => GameActivityCard(table: t),
                                  ).toList(),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    }).toList(),
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


void _showTablesList(BuildContext context, String category, String title, List<TableModel> tables) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '$category - $title',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (tables.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No tables found.')),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return ListTile(
                      leading: Icon(
                        Icons.table_restaurant,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        table.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        table.status.displayName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: table.status == TableStatus.available
                              ? AppColors.available
                              : AppColors.running,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.pop(context),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _StatusBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count $label',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
