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
            color: (table.status == TableStatus.running ? AppColors.running : AppColors.paused).withValues(alpha: 0.5),
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  );
                }
                return _RunningGameDetails(table: table, game: game);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningGameDetails extends ConsumerWidget {
  final TableModel table;
  final GameSession game;

  const _RunningGameDetails({required this.table, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch timer tick to refresh elapsed time and bill dynamically
    ref.watch(gameTimerProvider(game.id));
    final seconds = game.activeSeconds;

    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final timeStr = seconds >= 3600 ? '$h:$m:$s' : '$m:$s';

    final appSettings = ref.watch(appSettingsProvider);

    // Calculate real-time bill
    final breakdown = TablePricingConfig.calculateCharge(
      tableType: table.type,
      gameType: game.gameType,
      billingType: game.billingType,
      activeSeconds: seconds,
      framesPlayed: math.max(game.framesPlayed, game.totalFrames),
      pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
      gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: game.rounds,
    );
    final ordersTotal = game.orders.fold(0.0, (sum, order) => sum + order.total);
    final liveBill = breakdown.totalCharge + ordersTotal;

    final players = game.allPlayers.isEmpty ? 'No Players Assigned' : game.allPlayers.join(', ');
    final isRunning = table.status == TableStatus.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                table.name,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isRunning ? AppColors.running : AppColors.paused).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isRunning ? AppColors.running : AppColors.paused,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    table.status.displayName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isRunning ? AppColors.running : AppColors.paused,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(6),
        Text(
          '${table.type.displayName} • ${game.matchType.displayName} • ${game.billingType.displayName}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.group, size: 18, color: theme.colorScheme.primary),
              const Gap(10),
              Expanded(
                child: Text(
                  players,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
        Container(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: AppColors.running),
                const Gap(8),
                Text(
                  timeStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.running,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CURRENT LIVE BILL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '₹${liveBill.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
