import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_setup_sheet.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class StartGameSheet extends ConsumerWidget {
  const StartGameSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);
    final availableTables = tables.where((t) => t.status == TableStatus.available).toList();
    
    // Group tables dynamically
    final groupedTables = <TableType, List<TableModel>>{};
    for (final table in availableTables) {
      groupedTables.putIfAbsent(table.type, () => []).add(table);
    }

    // staff
    final currentStaff = ref.watch(currentStaffProvider).value;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Table',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Tables'),
                Tab(text: 'Other Games'),
              ],
            ),
            const Divider(height: 1),
            
            Expanded(
              child: availableTables.isEmpty
                  ? const Center(child: Text("No available tables right now."))
                  : TabBarView(
                      children: [
                        // Tables Tab
                        ListView(
                          padding: const EdgeInsets.all(20),
                          children: _buildTabGroups([TableType.snooker, TableType.indianPool, TableType.americanPool], groupedTables, context, currentStaff?.id ?? '', theme),
                        ),
                        // Other Games Tab
                        ListView(
                          padding: const EdgeInsets.all(20),
                          children: _buildTabGroups([TableType.ps5, TableType.pc, TableType.carrom, TableType.foosball, TableType.chess], groupedTables, context, currentStaff?.id ?? '', theme),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabGroups(List<TableType> types, Map<TableType, List<TableModel>> groupedTables, BuildContext context, String employeeId, ThemeData theme) {
    return types.map((type) {
      final tablesOfType = groupedTables[type] ?? [];
      if (tablesOfType.isEmpty) return const SizedBox.shrink();
      
      String title;
      switch (type) {
        case TableType.snooker: title = 'Snooker Tables'; break;
        case TableType.indianPool: title = 'Indian Pool Tables'; break;
        case TableType.americanPool: title = 'American Pool Tables'; break;
        case TableType.ps5: title = 'PS5 Consoles'; break;
        case TableType.pc: title = 'Gaming PCs'; break;
        case TableType.carrom: title = 'Carrom Boards'; break;
        case TableType.foosball: title = 'Foosball Tables'; break;
        case TableType.chess: title = 'Chess Boards'; break;
        case TableType.tableTennis: title = 'Table Tennis'; break;
        case TableType.steeringWheel: title = 'Steering Wheels'; break;
        case TableType.arcade: title = 'Arcade Machines'; break;
      }
      return _buildTableGroup(title, tablesOfType, context, employeeId, theme);
    }).toList();
  }

  Widget _buildTableGroup(String title, List<TableModel> tables, BuildContext context, String employeeId, ThemeData theme) {
    if (tables.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...tables.map((table) => _buildTableItem(table, context, employeeId, theme)),
        ],
      ),
    );
  }

  Widget _buildTableItem(TableModel table, BuildContext context, String employeeId, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success),
        ),
        title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(AppLocalizations.of(context)!.available),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Close this sheet, open the setup sheet
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => GameSetupSheet(
              table: table,
              employeeId: employeeId,
            ),
          );
        },
      ),
    );
  }
}
