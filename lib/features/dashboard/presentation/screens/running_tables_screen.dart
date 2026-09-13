import 'package:snooker_club/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/loading/empty_state_widget.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/active_game_card.dart';

class RunningTablesScreen extends ConsumerWidget {
  const RunningTablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(resolvedTablesProvider);
    final runningTables = tables
        .where(
          (t) =>
              t.status == TableStatus.running || t.status == TableStatus.paused,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.runningTables),
        centerTitle: false,
      ),
      body: runningTables.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.table_restaurant,
              title: 'No Running Tables',
              subtitle: 'All tables are currently idle or available.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: runningTables.length,
              itemBuilder: (context, index) {
                final table = runningTables[index];
                return _RunningTableTile(table: table);
              },
            ),
    );
  }
}

class _RunningTableTile extends ConsumerWidget {
  final TableModel table;

  const _RunningTableTile({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeGameAsync = ref.watch(activeGameProvider(table.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                (table.status == TableStatus.running
                        ? AppColors.running
                        : AppColors.paused)
                    .withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(
              '/games/table',
              extra: {
                'table': table,
                'selectedDate': DateTime.now(),
                'isToday': true,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: activeGameAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error loading active game: $e'),
              data: (game) {
                if (game == null) {
                  return Text(
                    'Table marked ${table.status.displayName} but no active game found.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  );
                }
                return ActiveGameCard(
                  table: table,
                  game: game,
                  isToday: true,
                  showTableName: true,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
