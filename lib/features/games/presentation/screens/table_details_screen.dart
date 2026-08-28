import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/games/presentation/widgets/game_setup_sheet.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class TableDetailsScreen extends ConsumerStatefulWidget {
  final TableModel table;
  final DateTime selectedDate;
  final bool isToday;

  const TableDetailsScreen({
    super.key,
    required this.table,
    required this.selectedDate,
    required this.isToday,
  });

  @override
  ConsumerState<TableDetailsScreen> createState() => _TableDetailsScreenState();
}

class _TableDetailsScreenState extends ConsumerState<TableDetailsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedGameIds = {};

  void _toggleSelection(String gameId) {
    setState(() {
      if (_selectedGameIds.contains(gameId)) {
        _selectedGameIds.remove(gameId);
        if (_selectedGameIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedGameIds.add(gameId);
      }
    });
  }

  void _enterSelectionMode(GameSession game) {
    if (game.status != TableStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select or delete an active game session.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _isSelectionMode = true;
      _selectedGameIds.add(game.id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedGameIds.clear();
    });
  }

  Future<void> _onDeleteSelected(List<GameSession> allCompletedGames) async {
    if (_selectedGameIds.isEmpty) return;

    // Show administrator passcode dialog
    final passcodeVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AdminPasscodeDialog(
        actionLabel: 'Delete',
        isDestructive: true,
      ),
    );

    if (passcodeVerified != true || !mounted) return;

    final selectedCount = _selectedGameIds.length;
    // Final confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete $selectedCount selected game${selectedCount > 1 ? 's' : ''}?',
        ),
        content: const Text(
          'This action cannot be undone. Inventory stock will be restored and revenue recalculated automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final gamesToDelete = allCompletedGames
        .where((g) => _selectedGameIds.contains(g.id))
        .toList();

    try {
      await ref
          .read(gameSessionControllerProvider.notifier)
          .deleteGames(gamesToDelete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$selectedCount game record${selectedCount > 1 ? 's' : ''} deleted successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeGameAsync = ref.watch(activeGameProvider(widget.table.id));
    final dateStr = dateToString(widget.selectedDate);
    final gamesAsync = ref.watch(
      tableGamesProvider((tableId: widget.table.id, date: dateStr)),
    );

    final completedGamesList =
        gamesAsync.asData?.value
            .where((g) => g.status == TableStatus.available)
            .toList() ??
        [];

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
                tooltip: 'Cancel selection',
              ),
              title: Text('${_selectedGameIds.length} Selected'),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 26,
                  ),
                  tooltip: 'Delete selected games',
                  onPressed: () => _onDeleteSelected(completedGamesList),
                ),
                const Gap(8),
              ],
            )
          : AppBar(
              title: Text(widget.table.name),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TableStatusChip(status: widget.table.status),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            // ── Current Game Section ──
            SliverToBoxAdapter(
              child: activeGameAsync.when(
                loading: () => const _LoadingCard(),
                error: (e, _) => _NoActiveGameCard(
                  table: widget.table,
                  isToday: widget.isToday,
                ),
                data: (game) {
                  if (game != null) {
                    return _ActiveGameCard(
                      game: game,
                      table: widget.table,
                      isToday: widget.isToday,
                    );
                  }
                  return _NoActiveGameCard(
                    table: widget.table,
                    isToday: widget.isToday,
                  );
                },
              ),
            ),

            // ── History Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'History — ${DateFormat('d MMMM yyyy').format(widget.selectedDate)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            gamesAsync.when(
              loading: () => const SliverToBoxAdapter(child: _LoadingCard()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'No history available.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (games) {
                final completedGames = games
                    .where((g) => g.status == TableStatus.available)
                    .toList();

                if (completedGames.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const Gap(8),
                            Text(
                              'No completed games yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = completedGames[index];
                    final isSelected = _selectedGameIds.contains(game.id);
                    return _HistoryCard(
                      game: game,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onLongPress: () => _enterSelectionMode(game),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(game.id);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BillDetailsScreen(session: game),
                            ),
                          );
                        }
                      },
                    );
                  }, childCount: completedGames.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: Gap(24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Active Game Card
// ─────────────────────────────────────────────

class _ActiveGameCard extends ConsumerStatefulWidget {
  final GameSession game;
  final TableModel table;
  final bool isToday;

  const _ActiveGameCard({
    required this.game,
    required this.table,
    required this.isToday,
  });

  @override
  ConsumerState<_ActiveGameCard> createState() => _ActiveGameCardState();
}

class _ActiveGameCardState extends ConsumerState<_ActiveGameCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = widget.game;
    final ordersTotal = game.orders.fold<double>(0, (s, o) => s + o.total);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  tableType: game.tableType,
                  gameType: game.gameType,
                  billingType: game.billingType,
                  activeSeconds: seconds,
                  framesPlayed: math.max(game.framesPlayed, game.totalFrames),
                  pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
                  gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
                  completedRounds: game.rounds,
                  customPrice: game.customPrice,
                );
                final h = (seconds ~/ 3600).toString().padLeft(2, '0');
                final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
                final s = (seconds % 60).toString().padLeft(2, '0');
                final timeStr = seconds >= 3600 ? '$h:$m:$s' : '$m:$s';

                return Row(
                  children: [
                    // Timer
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeStr,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: game.status == TableStatus.running
                                ? AppColors.running
                                : AppColors.paused,
                            letterSpacing: 2,
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            String displayStr = game.billingType.displayName;
                            if (game.billingType == BillingType.perMinute) {
                              final rate = game.customPrice ?? TablePricingConfig.getPerMinutePrice(
                                game.tableType, game.gameType, game.pricingSnapshot ?? appSettings.pricing
                              );
                              displayStr += ' • ₹${rate.toStringAsFixed(2)}/min';
                            }
                            return Text(
                              displayStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Current Charge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${charge.totalCharge.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Game charge',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                      icon: Icons.category,
                      label: game.gameType.displayName,
                    ),
                    _InfoChip(
                      icon: Icons.people,
                      label: game.allPlayers.join(', '),
                    ),
                    _InfoChip(
                      icon: Icons.emoji_events,
                      label: game.matchType.displayName,
                    ),
                    if (game.billingType == BillingType.perFrame &&
                        game.matchType == MatchType.loserPays)
                      _InfoChip(
                        icon: Icons.grid_3x3,
                        label:
                            'Round ${game.rounds.length + 1} (${game.rounds.length} completed)',
                      )
                    else if (game.totalFrames > 1 ||
                        game.billingType == BillingType.perFrame)
                      _InfoChip(
                        icon: Icons.grid_3x3,
                        label:
                            'Frame ${game.framesPlayed + 1}/${game.totalFrames}',
                      ),
                  ],
                ),
                const Gap(12),

                if (false) ...[  // Disabled: Race games no longer use point tracking
                  const Gap(12),
                  Text(
                    'Race Points Tracker (Target: ${game.targetPoints ?? '-'})',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(8),
                  ...game.allPlayers.map((player) {
                    final points = game.playerPoints?[player] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              final newPoints = Map<String, int>.from(
                                game.playerPoints ?? {},
                              );
                              newPoints[player] = (newPoints[player] ?? 0) - 1;
                              ref
                                  .read(gameSessionControllerProvider.notifier)
                                  .updatePlayerPoints(game.id, newPoints);
                            },
                          ),
                          Text(
                            '$points',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final newPoints = Map<String, int>.from(
                                game.playerPoints ?? {},
                              );
                              newPoints[player] = (newPoints[player] ?? 0) + 1;
                              ref
                                  .read(gameSessionControllerProvider.notifier)
                                  .updatePlayerPoints(game.id, newPoints);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                const Gap(12),
                // Completed Rounds
                if (game.billingType == BillingType.perFrame && game.rounds.isNotEmpty) ...[
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
                                      : 'Round ${r.roundNumber} · Winner: ${r.winner == 'Team A'
                                            ? game.teamA.join(' & ')
                                            : r.winner == 'Team B'
                                            ? game.teamB.join(' & ')
                                            : (r.winner ?? "N/A")}${r.loser != null ? " · Loser: ${r.loser == 'Team A'
                                                  ? game.teamA.join(' & ')
                                                  : r.loser == 'Team B'
                                                  ? game.teamB.join(' & ')
                                                  : r.loser}" : ""}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '₹${r.roundCost.toStringAsFixed(0)}',
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
                                '₹${o.total.toStringAsFixed(0)}',
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
                  if (ordersTotal > 0) ...[
                    const Gap(4),
                    Text(
                      'Orders total: ₹${ordersTotal.toStringAsFixed(0)}',
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
                label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
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
                      ? (game.matchType == MatchType.loserPays
                            ? 'Finish Round '
                            : 'Finish Frame ')
                      : 'End Game',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.creditStatus,
                ),
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
        content: const Text('Are you sure you want to cancel this game? This will free the table and delete the game record.'),
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
       Navigator.of(context).pop();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Game cancelled successfully'), backgroundColor: AppColors.success),
       );
    }
  }

  Future<void> _showOrdersSheet(GameSession game, BuildContext context) async {
    final updated = await showModalBottomSheet<List<GameOrder>>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          OrdersSheet(players: game.allPlayers, currentOrders: game.orders),
    );

    if (updated != null && mounted) {
      await ref
          .read(gameSessionControllerProvider.notifier)
          .updateOrders(game.id, updated);
    }
  }

  GameRound _buildCompletedFrameRecord({
    required GameSession game,
    required int roundNumber,
    String? winner,
    String? loser,
  }) {
    final appSettings = ref.read(appSettingsProvider);
    final pricing = game.pricingSnapshot ?? appSettings.pricing;
    final roundCost =
        TablePricingConfig.getPrice(
          game.tableType,
          game.gameType,
          game.billingType,
          pricing,
        ) ??
        0.0;
    final startTime = game.rounds.isNotEmpty
        ? (game.rounds.last.endTime ?? game.startTime)
        : game.startTime;
    final endTime = DateTime.now();
    final previousSeconds = game.rounds.fold<int>(
      0,
      (sum, r) => sum + (r.durationSeconds ?? 0),
    );
    final durationSeconds = (game.activeSeconds - previousSeconds).clamp(
      0,
      999999,
    );
    final graceMinutes = TablePricingConfig.frameGracePeriodMinutes;
    final overtimeSecs = durationSeconds - (graceMinutes * 60);
    final int overtimeMins = overtimeSecs > 0
        ? (overtimeSecs / 60.0).ceil()
        : 0;
    final double perMinRate = game.customPrice ?? TablePricingConfig.getPerMinutePrice(
      game.tableType,
      game.gameType,
      pricing,
    );
    final double overtimeChg = overtimeSecs > 0
        ? overtimeSecs * (perMinRate / 60.0)
        : 0.0;

    return GameRound(
      roundNumber: roundNumber,
      winner: winner,
      loser: loser,
      roundCost: roundCost,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      gracePeriodMinutes: graceMinutes,
      overtimeMinutes: overtimeMins,
      overtimeCharge: overtimeChg,
    );
  }

  Future<void> _handleEndGame(GameSession game, BuildContext context) async {
    if (game.gameType == GameType.race) {
      if (mounted && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BillingScreen(session: game)),
        );
      }
      return;
    }

    if (game.billingType == BillingType.perFrame) {
      if (game.matchType == MatchType.loserPays) {
        if (!context.mounted) return;
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => _RoundCompletionDialog(game: game),
        );
        if (result == null || !mounted || !context.mounted) return;

        final winner = result['winner'] as String;
        final loser = result['loser'] as String;
        final continueRound = result['continue'] as bool;

        final newRound = _buildCompletedFrameRecord(
          game: game,
          roundNumber: game.rounds.length + 1,
          winner: winner,
          loser: loser,
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
      } else {
        // Friendly match perFrame
        if (!context.mounted) return;
        final continueFrame = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Frame Complete'),
            content: Text(
              'Frame ${math.max(game.framesPlayed, game.totalFrames)} finished. Play one more round?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, Finish & Bill'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, Play Another'),
              ),
            ],
          ),
        );
        if (continueFrame == null || !mounted || !context.mounted) return;

        final newRound = _buildCompletedFrameRecord(
          game: game,
          roundNumber: game.rounds.length + 1,
          winner: 'Friendly',
        );
        final updatedRounds = [...game.rounds, newRound];

        if (continueFrame == true) {
          await Future.delayed(const Duration(milliseconds: 400));
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
                  'Frame ${newRound.roundNumber} recorded. Frame ${newRound.roundNumber + 1} started.',
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
    }

    // Non-perFrame billing (hourly/per-minute), go directly to billing
    if (mounted && context.mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => BillingScreen(session: game)));
    }
  }
}

class _RoundCompletionDialog extends StatefulWidget {
  final GameSession game;
  final bool isRace;
  const _RoundCompletionDialog({required this.game, this.isRace = false});

  @override
  State<_RoundCompletionDialog> createState() => _RoundCompletionDialogState();
}

class _RoundCompletionDialogState extends State<_RoundCompletionDialog> {
  String? _selectedWinner;
  String? _selectedLoser;

  @override
  void initState() {
    super.initState();
    final candidates = widget.game.mode == GameMode.team
        ? ['Team A', 'Team B']
        : widget.game.allPlayers;
    if (candidates.isNotEmpty) {
      _selectWinner(candidates.first);
    }
  }

  void _selectWinner(String winner) {
    setState(() {
      _selectedWinner = winner;
      if (widget.game.mode == GameMode.team) {
        _selectedLoser = winner == 'Team A' ? 'Team B' : 'Team A';
      } else {
        final remaining = widget.game.allPlayers
            .where((p) => p != winner)
            .toList();
        if (remaining.length == 1) {
          _selectedLoser = remaining.first;
        } else if (remaining.isNotEmpty &&
            (_selectedLoser == null || _selectedLoser == winner)) {
          _selectedLoser = remaining.first;
        }
      }
    });
  }

  String _getDisplayName(String id) {
    if (id == 'Team A') return widget.game.teamA.join(' & ');
    if (id == 'Team B') return widget.game.teamB.join(' & ');
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = widget.game.mode == GameMode.team
        ? ['Team A', 'Team B']
        : widget.game.allPlayers;
    final needsLoserSelect =
        widget.game.mode != GameMode.team && widget.game.allPlayers.length > 2;

    return AlertDialog(
      title: Text('Round ${widget.game.rounds.length + 1} Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who won this round?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidates.map((c) {
                final isSel = _selectedWinner == c;
                return ChoiceChip(
                  label: Text(_getDisplayName(c)),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) _selectWinner(c);
                  },
                );
              }).toList(),
            ),
            const Gap(16),
            if (needsLoserSelect) ...[
              Text(
                'Who lost this round? (Loser Pays)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates.where((c) => c != _selectedWinner).map((
                  c,
                ) {
                  final isSel = _selectedLoser == c;
                  return ChoiceChip(
                    label: Text(_getDisplayName(c)),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLoser = c);
                    },
                    selectedColor: AppColors.error.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const Gap(16),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Winner: ${_selectedWinner != null ? _getDisplayName(_selectedWinner!) : "None"}\nLoser (Pays): ${_selectedLoser != null ? _getDisplayName(_selectedLoser!) : "None"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Text(
              'Play One More Round?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_selectedWinner == null || _selectedLoser == null) return;
            Navigator.pop(context, {
              'winner': _selectedWinner!,
              'loser': _selectedLoser!,
              'continue': false,
            });
          },
          child: const Text('No, Finish & Bill'),
        ),
        FilledButton(
          onPressed: () {
            if (_selectedWinner == null || _selectedLoser == null) return;
            Navigator.pop(context, {
              'winner': _selectedWinner!,
              'loser': _selectedLoser!,
              'continue': true,
            });
          },
          child: const Text('Yes, Next Round'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// No Active Game Card
// ─────────────────────────────────────────────

class _NoActiveGameCard extends ConsumerWidget {
  final TableModel table;
  final bool isToday;

  const _NoActiveGameCard({required this.table, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final employeeId = authState.maybeWhen(
      data: (user) => user?.uid ?? 'admin',
      orElse: () => 'admin',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.available.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.table_restaurant,
            size: 64,
            color: AppColors.available.withValues(alpha: 0.6),
          ),
          const Gap(12),
          Text('Table Available', style: theme.textTheme.titleLarge),
          const Gap(4),
          Text(
            table.type.displayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(20),
          if (isToday)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showGameSetup(context, ref, employeeId),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else
            Text(
              'Cannot start a game on a past date.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  void _showGameSetup(BuildContext context, WidgetRef ref, String employeeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => GameSetupSheet(table: table, employeeId: employeeId),
    );
  }
}

// ─────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final GameSession game;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.game,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('hh:mm a');
    final duration = game.endTime != null
        ? _formatDuration(game.activeSeconds)
        : '';

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (isSelectionMode) ...[
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 22,
              ),
              const Gap(12),
            ],
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dtFmt.format(game.startTime),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (game.endTime != null)
                  Text(
                    dtFmt.format(game.endTime!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const Gap(12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.allPlayers.join(' vs '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    '${game.billingType.displayName} · $duration',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (game.winnerDisplayName != null)
                    Text(
                      'Winner: ${game.winnerDisplayName}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            // Total + Payment
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (game.grandTotal != null)
                  Text(
                    '₹${game.grandTotal!.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                if (game.paymentMethod != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _paymentColor(
                        game.paymentMethod!,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      game.paymentMethod!.displayName,
                      style: TextStyle(
                        color: _paymentColor(game.paymentMethod!),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  Color _paymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.success;
      case PaymentMethod.upi:
        return AppColors.running;
      case PaymentMethod.credit:
        return AppColors.creditStatus;
    }
  }
}

// ─────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────

class _TableStatusChip extends StatelessWidget {
  final TableStatus status;

  const _TableStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.available;
      case TableStatus.running:
        return AppColors.running;
      case TableStatus.paused:
        return AppColors.paused;
      case TableStatus.billing:
        return AppColors.billing;
    }
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SkeletonLoader(height: 200, borderRadius: 20),
    );
  }
}
