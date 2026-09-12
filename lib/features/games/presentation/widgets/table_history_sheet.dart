import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/repeat_game_sheet.dart';

class TableHistorySheet extends ConsumerWidget {
  final TableModel table;

  const TableHistorySheet({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final gamesAsync = ref.watch(tableGamesProvider((tableId: table.id, date: todayStr)));

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(' - Today\'s History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]
          ),
          const Divider(),
          gamesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => const Center(child: Text('Error loading history')),
            data: (allGames) {
              final completedGames = allGames.where((g) => g.status == TableStatus.available).toList();
              // sort by endTime descending
              completedGames.sort((a, b) {
                if (a.endTime == null && b.endTime == null) return 0;
                if (a.endTime == null) return 1;
                if (b.endTime == null) return -1;
                return b.endTime!.compareTo(a.endTime!);
              });

              final recentGames = completedGames.take(4).toList();

              if (recentGames.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No completed games today.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: recentGames.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  final game = recentGames[index];
                  return _HistoryListTile(game: game, table: table);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  final GameSession game;
  final TableModel table;

  const _HistoryListTile({required this.game, required this.table});

  String _formatDuration(int seconds) {
    final dur = Duration(seconds: seconds);
    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
    }
    return '${dur.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('hh:mm a');
    final duration = game.endTime != null ? _formatDuration(game.activeSeconds) : '';

    final num price = game.grandTotal ?? 0;
    
    // Fallback if players list is empty
    final players = game.allPlayers.isEmpty ? ['Default 1'] : game.allPlayers;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dtFmt.format(game.startTime), style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (game.endTime != null)
                Text(dtFmt.format(game.endTime!), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const Gap(12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(players.join(' vs '), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const Gap(2),
                Text('$duration  •  ₹$price', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          // Repeat Action
          IconButton(
            icon: const Icon(Icons.replay_circle_filled, color: AppColors.primary, size: 28),
            onPressed: () {
              Navigator.pop(context); // close sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => RepeatGameSheet(originalSession: game),
              );
            },
            tooltip: 'Repeat Game',
          ),
        ],
      ),
    );
  }
}