import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_activity_card.dart';

class GameActivityScreen extends ConsumerWidget {
  const GameActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tablesAsync = ref.watch(resolvedTablesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text('Staging Club', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () {
            // Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Admin', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(Icons.person, size: 16, color: theme.colorScheme.surface),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final tables = tablesAsync;
          if (tables.isEmpty) {
            return Center(child: Text('No tables configured.', style: TextStyle(color: theme.colorScheme.onSurface)));
          }

          final snookerTables = tables.where((t) => t.type == TableType.snooker).toList();
          final poolTables = tables.where((t) => t.type == TableType.indianPool || t.type == TableType.americanPool).toList();
          final consoleTables = tables.where((t) => t.type == TableType.ps5 || t.type == TableType.ps4 || t.type == TableType.pc || t.type == TableType.arcade).toList();
          
          final existingTypes = <String>[];
          if (snookerTables.isNotEmpty) existingTypes.add('Snooker');
          if (poolTables.isNotEmpty) existingTypes.add('Pool');
          if (consoleTables.isNotEmpty) existingTypes.add('Console & PC');
          
          final otherTables = tables.where((t) => !snookerTables.contains(t) && !poolTables.contains(t) && !consoleTables.contains(t)).toList();
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
                      if (type == 'Snooker') tabTables = snookerTables;
                      else if (type == 'Pool') tabTables = poolTables;
                      else if (type == 'Console & PC') tabTables = consoleTables;
                      else if (type == 'Other') tabTables = otherTables;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        itemCount: tabTables.length,
                        itemBuilder: (context, index) {
                          return GameActivityCard(table: tabTables[index]);
                        },
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

