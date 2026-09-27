import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;

import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';
import 'package:snooker_club/features/games/presentation/widgets/payer_selection_widget.dart';
import 'package:snooker_club/features/games/presentation/screens/manual_game_setup_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/table_history_sheet.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/games/presentation/widgets/alarm_setup_sheet.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';
import 'package:snooker_club/features/games/presentation/widgets/mark_pending_dialog.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';

class ActiveGameCard extends ConsumerStatefulWidget {
  final GameSession game;
  final TableModel table;
  final bool isToday;
  final bool showTableName;

  const ActiveGameCard({
    required this.game,
    required this.table,
    required this.isToday,
    this.showTableName = false,
    super.key,
  });

  @override
  ConsumerState<ActiveGameCard> createState() => _ActiveGameCardState();
}

class _ActiveGameCardState extends ConsumerState<ActiveGameCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = widget.game;
    final ordersTotal = game.orders.fold<double>(0, (s, o) => s + o.total);
    final manualGamesTotal = game.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount);
    final totalExtras = ordersTotal + manualGamesTotal;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: game.status == TableStatus.running
              ? AppColors.running
              : AppColors.paused,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color:
                  (game.status == TableStatus.running
                          ? AppColors.running
                          : AppColors.paused)
                      .withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                ref.watch(gameTimerProvider(game.id));
                final seconds = game.activeSeconds;
                final appSettings = ref.watch(appSettingsProvider);
                final charge = TablePricingConfig.calculateCharge(
                  table: widget.table,
                  gameType: GameType.standard,
                  billingType: game.billingType,
                  activeSeconds: seconds,
                  framesPlayed: math.max(game.framesPlayed, game.totalFrames),
                  pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
                  gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
                  completedRounds: game.rounds,
                  customPrice: game.customPrice,
                  customExtraCharge: game.customExtraCharge,
                  playersCount: game.allPlayers.length,
                  coinQuantity: game.coinQuantity,
        customMinutes: game.customMinutes,
                  customMinutes: game.customMinutes,
                  isMinimumBillEnabled: game.isMinimumBillEnabled,
                  minimumBillAmount: game.minimumBillAmount,
                );
                final h = (seconds ~/ 3600).toString().padLeft(2, '0');
                final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
                final s = (seconds % 60).toString().padLeft(2, '0');
                final timeStr = seconds >= 3600 ? '$h:$m:$s' : '$m:$s';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showTableName) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.table.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (game.status == TableStatus.running
                                          ? AppColors.running
                                          : AppColors.paused)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: game.status == TableStatus.running
                                        ? AppColors.running
                                        : AppColors.paused,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  game.status.displayName.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: game.status == TableStatus.running
                                        ? AppColors.running
                                        : AppColors.paused,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          const Gap(8),
                          _BellIcon(gameId: game.id, tableName: widget.table.name),
                          const Gap(4),
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (_) => TableHistorySheet(table: widget.table),
                              );
                            },
                            icon: const Icon(Icons.history),
                            tooltip: 'History',
                          ),
                        ],
                      ),
                      const Gap(12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timer
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  timeStr,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: game.status == TableStatus.running
                                        ? AppColors.running
                                        : AppColors.paused,
                                    letterSpacing: 2,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  String displayStr =
                                      game.billingType.displayName;
                                  if (game.billingType == BillingType.perMinute) {
                                    final rate =
                                        game.customPrice ??
                                        TablePricingConfig.getPerMinutePrice(
                                          widget.table,
                                          GameType.standard,
                                          game.pricingSnapshot ??
                                              appSettings.pricing,
                                        );
                                    displayStr +=
                                        ' • ₹${rate.toStringAsFixed(2)}/min';
                                  }
                                  if (game.createdByName != null) {
                                    displayStr += '\nStarted by: ${game.createdByName}';
                                  }
                                  return Text(
                                    displayStr,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        // Current Charge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${charge.totalCharge.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.2,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Game charge',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.sports_esports,
                      label: game.tableType.displayName,
                    ),
                    _InfoChip(
                      icon: Icons.people,
                      label: game.allPlayers.join(', '),
                    ),
                    if (game.totalFrames > 1 ||
                        game.billingType == BillingType.perFrame)
                      _InfoChip(
                        icon: Icons.grid_3x3,
                        label:
                            'Frame ${game.framesPlayed + 1}/${game.totalFrames}',
                      ),
                  ],
                ),
                const Gap(12),

                // Completed Rounds
                if (game.billingType == BillingType.perFrame &&
                    game.rounds.isNotEmpty) ...[
                  Text(
                    'Completed Rounds',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(6),
                  ...game.rounds
                      .take(3)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.winner == 'Friendly'
                                      ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                                      : 'Round ${r.roundNumber} · Winner: ${r.winner ?? "N/A"}${r.loser != null ? " · Loser: ${r.loser}" : ""}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '\u20B9${r.roundCost.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (game.rounds.length > 3)
                    Text(
                      '+${game.rounds.length - 3} more rounds',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Gap(12),
                ],

                // Orders
                if (game.orders.isNotEmpty) ...[
                  Text(
                    'Orders',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(6),
                  ...game.orders
                      .take(3)
                      .map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${o.quantity}x ${o.productName}${o.playerName != null ? ' · ${o.playerName}' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '\u20B9${o.total.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (game.orders.length > 3)
                    Text(
                      '+${game.orders.length - 3} more',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (totalExtras > 0) ...[
                    const Gap(4),
                    Text(
                      'Extras total: \u20B9${totalExtras.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const Gap(8),
                ],
                const Gap(4),

                // ── Action Buttons ──
                if (widget.isToday) _buildActionButtons(game, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(GameSession game, BuildContext context) {
    final controller = ref.read(gameSessionControllerProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            // Pause / Resume (Only shown if allowed or already paused)
            if (TablePricingConfig.allowPauseResume ||
                game.status == TableStatus.paused) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (game.status == TableStatus.running) {
                      await controller.pauseGame(game.id, game.tableId);
                    } else {
                      await controller.resumeGame(game.id, game.tableId);
                    }
                  },
                  icon: Icon(
                    game.status == TableStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    game.status == TableStatus.running ? 'Pause' : 'Resume',
                  ),
                ),
              ),
              const Gap(8),
            ],
            // Add Orders
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrdersSheet(game, context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Orders'),
              ),
            ),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleCancelGame(game, context),
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _handleEndGame(game, context),
                icon: const Icon(Icons.flag),
                label: Text(
                  game.billingType == BillingType.perFrame
                      ? 'Finish Frame'
                      : 'Finish Game',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.creditStatus,
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.edit_document, size: 16),
                label: const Text(
                  'Manual Entry',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  final employeeId = ref.read(currentStaffProvider).value?.id ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManualGameSetupScreen(
                        employeeId: employeeId,
                        isCompletedGame: true,
                        initialTable: widget.table,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  foregroundColor: Colors.orange.shade700,
                ),
                icon: const Icon(Icons.shopping_basket, size: 16),
                label: const Text(
                  'Mark as Pending',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _handleMarkAsPending(game, context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleCancelGame(GameSession game, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Game?'),
        content: const Text(
          'Are you sure you want to cancel this game? This will free the table and delete the game record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted || !context.mounted) return;

    await ref
        .read(gameSessionControllerProvider.notifier)
        .cancelGame(game.id, game.tableId, game.orders);

    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _showOrdersSheet(GameSession game, BuildContext context) async {
    final updated = await showModalBottomSheet<AddItemsResult>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (_) => OrdersSheet(
        players: game.allPlayers,
        currentOrders: game.orders,
        currentManualGameCharges: game.manualGameCharges,
        enableGamesTab: true,
      ),
    );

    if (updated != null && mounted) {
      await ref
          .read(gameSessionControllerProvider.notifier)
          .updateOrders(game.id, game.orders, updated.orders, game.manualGameCharges, updated.manualGameCharges);
    }
  }

  GameRound _buildCompletedFrameRecord({
    required GameSession game,
    required int roundNumber,
    required List<String> framePayers,
  }) {
    final now = DateTime.now();
    final duration = now.difference(game.startTime);
    int activeSeconds = duration.inSeconds;

    final appSettings = ref.read(appSettingsProvider);
    final charge = TablePricingConfig.calculateCharge(
      table: widget.table,
      gameType: GameType.standard,
      billingType: game.billingType,
      activeSeconds: activeSeconds,
      framesPlayed: roundNumber,
      pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
      gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: game.rounds,
      customPrice: game.customPrice,
      customExtraCharge: game.customExtraCharge,
      playersCount: game.allPlayers.length,
      coinQuantity: game.coinQuantity,
        customMinutes: game.customMinutes,
      isMinimumBillEnabled: game.isMinimumBillEnabled,
      minimumBillAmount: game.minimumBillAmount,
    );

    final currentOvertimeMinutes =
        charge.overtimeMinutes -
        game.rounds.fold<int>(0, (s, r) => s + (r.overtimeMinutes ?? 0));
    final currentOvertimeCharge =
        charge.overtimeCharge -
        game.rounds.fold<double>(0.0, (s, r) => s + (r.overtimeCharge ?? 0.0));

    final previousBaseTotal = game.rounds.fold<double>(
      0.0,
      (s, r) => s + r.roundCost,
    );
    final roundCost = charge.baseCharge - previousBaseTotal;

    return GameRound(
      roundNumber: roundNumber,
      framePayers: framePayers,
      roundCost: roundCost,
      durationSeconds:
          activeSeconds -
          game.rounds.fold<int>(0, (s, r) => s + (r.durationSeconds ?? 0)),
      overtimeMinutes: currentOvertimeMinutes > 0
          ? currentOvertimeMinutes
          : null,
      overtimeCharge: currentOvertimeCharge > 0 ? currentOvertimeCharge : null,
    );
  }

  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.billingType == BillingType.perFrame) {
      if (!context.mounted) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => _RoundCompletionDialog(game: game),
      );
      if (result == null || !mounted || !context.mounted) return;

      final framePayers = result['framePayers'] as List<String>;
      final continueRound = result['continue'] as bool;

      final newRound = _buildCompletedFrameRecord(
        game: game,
        roundNumber: game.rounds.length + 1,
        framePayers: framePayers,
      );
      final updatedRounds = [...game.rounds, newRound];

      if (continueRound) {
        await ref
            .read(gameSessionControllerProvider.notifier)
            .updateGameRounds(
              game.id,
              updatedRounds,
              updatedRounds.length + 1,
              updatedRounds.length,
            );
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Round ${newRound.roundNumber} recorded. Round ${newRound.roundNumber + 1} started.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      } else {
        final updatedSession = game.copyWith(
          rounds: updatedRounds,
          framesPlayed: updatedRounds.length,
          totalFrames: updatedRounds.length,
        );
        if (mounted && context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BillingScreen(session: updatedSession),
            ),
          );
        }
        return;
      }
    }

    // Non-perFrame billing (hourly/per-minute), go directly to billing
    if (mounted && context.mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => BillingScreen(session: game)));
    }
  }

  Future<void> _handleMarkAsPending(GameSession game, BuildContext context) async {
    final selectedPlayers = await showDialog<List<PlayerSelection>?>(
      context: context,
      builder: (ctx) => const MarkPendingDialog(),
    );

    if (selectedPlayers == null || selectedPlayers.isEmpty) return;

    if (!context.mounted) return;

    // Wait slightly to let dialog close
    await Future.delayed(const Duration(milliseconds: 100));

    final appSettings = ref.read(appSettingsProvider);

    final charge = TablePricingConfig.calculateCharge(
      table: widget.table,
      gameType: game.gameType,
      billingType: game.billingType,
      activeSeconds: game.activeSeconds,
      framesPlayed: math.max(game.framesPlayed, game.totalFrames),
      pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
      gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: game.rounds,
      customPrice: game.customPrice,
      customExtraCharge: game.customExtraCharge,
      playersCount: game.allPlayers.length,
      coinQuantity: game.coinQuantity,
        customMinutes: game.customMinutes,
      isMinimumBillEnabled: game.isMinimumBillEnabled,
      minimumBillAmount: game.minimumBillAmount,
    );

    final gameCharge = charge.totalCharge;
    final manualGamesTotal = game.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount);
    final ordersTotal = game.orders.fold<double>(0, (s, o) => s + o.total);
    final manualGamesTotal = game.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount);
    final totalExtras = ordersTotal + manualGamesTotal;
    final grandTotal = gameCharge + ordersTotal + manualGamesTotal;
    final finalTotal = math.max(0.0, grandTotal - (game.discountAmount ?? 0.0));

    // For pending bills, we take games as is without rounding off. 
    // Rounding is applied during final combined settlement.
    final roundedTotal = finalTotal;

    final finalSession = game.copyWith(
      endTime: DateTime.now(),
      gameCharge: gameCharge,
      baseGameCharge: charge.baseCharge,
      overtimeMinutes: charge.overtimeMinutes,
      overtimeCharge: charge.overtimeCharge,
      ordersTotal: ordersTotal,
      grandTotal: finalTotal,
      roundedAmount: roundedTotal,
      finalAmount: roundedTotal,
    );

    final repo = ref.read(gamesRepositoryProvider);
    final creditRepo = ref.read(creditRepositoryProvider);
    final allProfiles = ref.read(allCustomersProvider).value ?? [];
    final now = DateTime.now();

    final List<Map<String, String>> resolvedPlayers = [];

    for (final p in selectedPlayers) {
      if (p.id != null) {
        resolvedPlayers.add({'id': p.id!, 'name': p.name});
      } else {
        // Find existing match just in case
        final existingMatch = allProfiles.cast<PlayerProfile?>().firstWhere(
            (profile) => profile?.name.toLowerCase() == p.name.trim().toLowerCase(),
            orElse: () => null);

        if (existingMatch != null) {
          resolvedPlayers.add({'id': existingMatch.id, 'name': existingMatch.name});
        } else {
          // Create new profile
          final newId = FirebaseFirestore.instance.collection('dummy').doc().id;
          final newProfile = PlayerProfile(
            id: newId,
            name: p.name.trim(),
            lastTransactionDate: now,
          );
          await creditRepo.savePlayerProfile(newProfile);
          resolvedPlayers.add({'id': newId, 'name': newProfile.name});
        }
      }
    }

    if (resolvedPlayers.length == 1) {
      await repo.markAsPendingBill(
        finalSession,
        customerId: resolvedPlayers[0]['id']!,
        customerName: resolvedPlayers[0]['name']!,
      );
    } else {
      await repo.markAsPendingBillWithSplits(finalSession, resolvedPlayers);
    }
  }

}

class _RoundCompletionDialog extends StatefulWidget {
  final GameSession game;
  const _RoundCompletionDialog({required this.game});

  @override
  State<_RoundCompletionDialog> createState() => _RoundCompletionDialogState();
}

class _RoundCompletionDialogState extends State<_RoundCompletionDialog> {
  late List<String> _selectedPayers;

  @override
  void initState() {
    super.initState();
    _selectedPayers = List.from(widget.game.allPlayers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allDefault = widget.game.allPlayers.every(
      (p) => p.toLowerCase().startsWith('default'),
    );

    return AlertDialog(
      title: const Text('Frame Completed'),
      content: allDefault
          ? const Text(
              'The frame has been completed. What would you like to do next?',
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PayerSelectionWidget(
                    allPlayers: widget.game.allPlayers,
                    selectedPayers: _selectedPayers,
                    onChanged: (newPayers) {
                      setState(() {
                        _selectedPayers = newPayers;
                      });
                    },
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'framePayers': _selectedPayers,
            'continue': true,
          }),
          child: const Text('Play Another'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'framePayers': _selectedPayers,
            'continue': false,
          }),
          child: const Text('Finish & Bill'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const Gap(4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}


class _BellIcon extends StatefulWidget {
  final String gameId;
  final String tableName;

  const _BellIcon({required this.gameId, required this.tableName});

  @override
  State<_BellIcon> createState() => _BellIconState();
}

class _BellIconState extends State<_BellIcon> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: TableAlarmService().onAlarmsChanged,
      builder: (context, _) {
        final alarm = TableAlarmService().getAlarmInfo(widget.gameId);
        final isActive = alarm != null;
        final theme = Theme.of(context);

        return IconButton(
          onPressed: () {
            AlarmSetupSheet.show(context, widget.gameId, widget.tableName);
          },
          icon: Icon(
            isActive ? Icons.notifications_active : Icons.notifications_none,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Set Reminder',
        );
      },
    );
  }
}





