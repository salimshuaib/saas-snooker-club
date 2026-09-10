
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/running_game_tile.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_setup_sheet.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class GameActivityScreen extends ConsumerWidget {
  const GameActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(resolvedTablesProvider);
    final billiardsTables = tables.where((t) => !t.type.isOtherGame).toList();
    final otherGamesTables = tables.where((t) => t.type.isOtherGame).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Activity'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Table Games'),
              Tab(text: 'Other Games'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ActivityTabView(tables: billiardsTables),
            _ActivityTabView(tables: otherGamesTables),
          ],
        ),
      ),
    );
  }
}

class _ActivityTabView extends ConsumerWidget {
  final List<TableModel> tables;

  const _ActivityTabView({required this.tables});

  void _showStartGameSheet(BuildContext context, TableModel table, WidgetRef ref) {
    final currentStaff = ref.read(currentStaffProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GameSetupSheet(
        table: table,
        employeeId: currentStaff?.id ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runningTables = tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).toList();
    final availableTables = tables.where((t) => t.status == TableStatus.available).toList();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (runningTables.isNotEmpty) ...[
          Text(
            'LIVE GAMES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Gap(12),
          ...runningTables.map((table) => RunningGameTile(table: table)),
          const Gap(24),
        ],
        
        Text(
          'AVAILABLE TO START',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(12),
        if (availableTables.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No resources available.'),
            ),
          )
        else
          ...availableTables.map((table) => Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(table.type.displayName),
              trailing: FilledButton(
                onPressed: () => _showStartGameSheet(context, table, ref),
                child: const Text('Start'),
              ),
            ),
          )),
      ],
    );
  }
}




