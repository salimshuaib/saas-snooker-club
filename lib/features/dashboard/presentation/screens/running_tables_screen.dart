import 'package:snooker_club/features/games/presentation/widgets/running_game_tile.dart';
import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/widgets/loading/empty_state_widget.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class RunningTablesScreen extends ConsumerWidget {
  const RunningTablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(resolvedTablesProvider);
    final runningTables = tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).toList();

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
                return RunningGameTile(table: table);
              },
            ),
    );
  }
}



