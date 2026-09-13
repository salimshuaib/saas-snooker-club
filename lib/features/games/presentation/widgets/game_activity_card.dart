import 'package:gap/gap.dart';
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/games/presentation/screens/manual_game_setup_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/table_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_setup_dialog.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/active_game_card.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class GameActivityCard extends ConsumerWidget {
  final TableModel table;

  const GameActivityCard({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAvailable = table.status == TableStatus.available;
    final isRunning = table.status == TableStatus.running;
    final isPaused = table.status == TableStatus.paused;

    final gameAsync = ref.watch(activeGameProvider(table.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable
                            ? AppColors.available
                            : (isRunning
                                  ? AppColors.success
                                  : AppColors.paused),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable
                          ? 'Available'
                          : (isRunning ? 'RUNNING' : 'PAUSED'),
                      style: TextStyle(
                        color: isAvailable
                            ? AppColors.available
                            : (isRunning
                                  ? AppColors.success
                                  : AppColors.paused),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ).copyWith(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final employeeId =
                          ref.read(currentStaffProvider).value?.id ?? '';
                      final result = await showDialog<GameSession>(
                        context: context,
                        builder: (_) => GameSetupDialog(
                          table: table,
                          employeeId: employeeId,
                        ),
                      );
                      if (result != null &&
                          result.status == TableStatus.billing &&
                          context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BillingScreen(session: result),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (_) => TableHistorySheet(table: table),
                            );
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('History'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final employeeId =
                                ref.read(currentStaffProvider).value?.id ?? '';
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ManualGameSetupScreen(
                                  employeeId: employeeId,
                                  isCompletedGame: false,
                                  initialTable: table,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_document, size: 18),
                          label: const Text(
                            'Manual Entry',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // RUNNING/PAUSED DETAILS
          if (!isAvailable)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: gameAsync.when(
                data: (game) {
                  if (game == null) return const SizedBox();
                  return Theme(
                    data: theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        bodyColor: theme.colorScheme.onSurface,
                        displayColor: theme.colorScheme.onSurface,
                      ),
                    ),
                    child: ActiveGameCard(
                      table: table,
                      game: game,
                      isToday: true,
                      showTableName: false,
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Error', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
