import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_setup_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/running_tables_screen.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class GameActivityCard extends ConsumerStatefulWidget {
  final TableModel table;

  const GameActivityCard({
    super.key,
    required this.table,
  });

  @override
  ConsumerState<GameActivityCard> createState() => _GameActivityCardState();
}

class _GameActivityCardState extends ConsumerState<GameActivityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = widget.table.status == TableStatus.available;
    final isRunning = widget.table.status == TableStatus.running;
    final isPaused = widget.table.status == TableStatus.paused;

    final gameAsync = ref.watch(activeGameProvider(widget.table.id));

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
          InkWell(
            onTap: isAvailable ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            } : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.table.name,
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
                              color: isAvailable ? AppColors.available : (isRunning ? AppColors.success : AppColors.paused),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? 'Available' : (isRunning ? 'RUNNING' : 'PAUSED'),
                            style: TextStyle(
                              color: isAvailable ? AppColors.available : (isRunning ? AppColors.success : AppColors.paused),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isAvailable) ...[
                    Row(
                      children: [
                        if (!_isExpanded)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isExpanded = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // EXPANDED SETUP FORM
          if (_isExpanded && isAvailable)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: GameSetupSheet(
                table: widget.table,
                employeeId: ref.watch(currentStaffProvider).value?.id ?? '',
                isInline: true,
                onCancel: () => setState(() => _isExpanded = false),
              ),
            ),
            
          // RUNNING/PAUSED DETAILS
          if (!isAvailable)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: gameAsync.when(
                data: (game) {
                  if (game == null) return const SizedBox();
                  return Theme(
                    data: theme.copyWith(
                       textTheme: theme.textTheme.apply(
                         bodyColor: theme.colorScheme.onSurface,
                         displayColor: theme.colorScheme.onSurface,
                       )
                    ),
                    child: RunningGameDetails(table: widget.table, game: game),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

