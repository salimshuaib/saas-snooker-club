import 'package:flutter/material.dart';
import 'package:snooker_club/features/games/presentation/widgets/pending_bills_icon_badge.dart';
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
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/features/floors/presentation/widgets/floor_selector_sheet.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

class GameActivityScreen extends ConsumerWidget {
  const GameActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tablesAsync = ref.watch(floorFilteredTablesProvider);
    final club = ref.watch(clubProfileProvider).value;
    final clubName = club?.clubName ?? 'Loading...';

    final currentStaff = ref.watch(currentStaffProvider).value;
    final selectedFloor = ref.watch(selectedFloorProvider);
    final isFloorsEnabled = ref.watch(hasFloorsProvider);

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

    String headerTitle = clubName;
    if (isFloorsEnabled) {
      if (selectedFloor != null) {
        headerTitle = '${selectedFloor.name}';
      } else {
        headerTitle = 'All Floors';
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
          headerTitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {
                if (isFloorsEnabled) {
                  AppModal.showBottomSheet(
                    context: context,
                    builder: (_) => const FloorSelectorSheet(),
                  );
                } else {
                  // If floors aren't configured, tapping could guide them to setup, but profile is fine for now
                  context.push(RouteNames.floorManagement);
                }
              },
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
          ),
        ],
      ),
      floatingActionButton: const PendingBillsIconBadge(isFab: true),
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
                                  Expanded(
                                    child: Text(
                                      sortedKeys[i].displayName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (i == 0) ...[
                                    Builder(
                                      builder: (innerContext) {
                                        final notSureCount = tables.where((t) => (t.status == TableStatus.running || t.status == TableStatus.paused) && t.isTimeNotSure).length;
                                        if (notSureCount == 0) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: _StatusBadge(
                                            label: 'Not Sure',
                                            count: notSureCount,
                                            color: Colors.red,
                                            onTap: () => _showTablesList(
                                              innerContext,
                                              'All Tables',
                                              'Not Sure Games',
                                              tables.where((t) => (t.status == TableStatus.running || t.status == TableStatus.paused) && t.isTimeNotSure).toList(),
                                              allTables: tables,
                                              existingTypes: existingTypes,
                                              snookerTables: snookerTables,
                                              poolTables: poolTables,
                                              consoleTables: consoleTables,
                                              otherTables: otherTables,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Builder(
                                      builder: (innerContext) => _StatusBadge(
                                        label: 'Running',
                                        count: tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).length,
                                        color: AppColors.running,
                                        onTap: () => _showTablesList(
                                          innerContext,
                                          'All Tables',
                                          'Running Games',
                                          tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).toList(),
                                          allTables: tables,
                                          existingTypes: existingTypes,
                                          snookerTables: snookerTables,
                                          poolTables: poolTables,
                                          consoleTables: consoleTables,
                                          otherTables: otherTables,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Builder(
                                      builder: (innerContext) => _StatusBadge(
                                        label: 'Available',
                                        count: tables.where((t) => t.status == TableStatus.available).length,
                                        color: AppColors.available,
                                        onTap: () => _showTablesList(
                                          innerContext,
                                          'All Tables',
                                          'Available Games',
                                          tables.where((t) => t.status == TableStatus.available).toList(),
                                          allTables: tables,
                                          existingTypes: existingTypes,
                                          snookerTables: snookerTables,
                                          poolTables: poolTables,
                                          consoleTables: consoleTables,
                                          otherTables: otherTables,
                                        ),
                                      ),
                                    ),
                                  ]
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


void _showTablesList(
  BuildContext context,
  String category,
  String title,
  List<TableModel> tables, {
  List<TableModel>? allTables,
  List<String>? existingTypes,
  List<TableModel>? snookerTables,
  List<TableModel>? poolTables,
  List<TableModel>? consoleTables,
  List<TableModel>? otherTables,
}) {
  final theme = Theme.of(context);
  AppModal.showBottomSheet(
    context: context,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      bool isTapped = false;
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
                    onPressed: () => Navigator.pop(sheetContext),
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
                  itemBuilder: (_, index) {
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            table.isTimeNotSure 
                                ? 'NOT SURE' 
                                : table.status.displayName.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: table.isTimeNotSure
                                  ? Colors.red
                                  : (table.status == TableStatus.available
                                      ? AppColors.available
                                      : (table.status == TableStatus.paused 
                                          ? AppColors.paused 
                                          : AppColors.running)),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () {
                        if (isTapped) return;
                        isTapped = true;
                        
                        // Close the bottom sheet
                        Navigator.pop(sheetContext);

                        // Show the game activity dialog
                        AppModal.showDialog(
                          context: context,
                          builder: (ctx) => _TableDialogWrapper(table),
                        );
                      },
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

class _TableDialogWrapper extends ConsumerStatefulWidget {
  final TableModel initialTable;
  const _TableDialogWrapper(this.initialTable);
  @override
  ConsumerState<_TableDialogWrapper> createState() => _TableDialogWrapperState();
}

class _TableDialogWrapperState extends ConsumerState<_TableDialogWrapper> {
  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(resolvedTablesProvider);
    final currentTable = tables.firstWhere(
      (t) => t.id == widget.initialTable.id,
      orElse: () => widget.initialTable,
    );

    ref.listen(resolvedTablesProvider, (prev, next) {
      if (next != null) {
        final prevTable = prev?.firstWhere(
          (t) => t.id == widget.initialTable.id,
          orElse: () => widget.initialTable,
        ) ?? widget.initialTable;
        final currTable = next.firstWhere(
          (t) => t.id == widget.initialTable.id,
          orElse: () => widget.initialTable,
        );
        if (prevTable.status != TableStatus.available && currTable.status == TableStatus.available) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final route = ModalRoute.of(context);
                if (route != null) {
                  if (route.isCurrent) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).removeRoute(route);
                  }
                }
              }
            });
          }
        }
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: GameActivityCard(table: currentTable),
            ),
          ),
        ],
      ),
    );
  }
}
