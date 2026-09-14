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
import 'package:snooker_club/features/games/presentation/widgets/game_setup_dialog.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/payer_selection_widget.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/active_game_card.dart';

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
      builder: (_) =>
          const AdminPasscodeDialog(actionLabel: 'Delete', isDestructive: true),
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
// No Active Game Card
// ─────────────────────────────────────────────


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
                if ((game.finalAmount ?? game.grandTotal) != null)
                  Text(
                    '\u20B9${(game.finalAmount ?? game.grandTotal)!.toStringAsFixed(0)}',
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
