import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/core/widgets/shared/date_navigation_header.dart';

import 'package:snooker_club/core/theme/app_shadows.dart';
import 'package:snooker_club/core/providers/app_providers.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
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

  void _enterSelectionMode(String gameId) {
    setState(() {
      _isSelectionMode = true;
      _selectedGameIds.add(gameId);
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
            'Successfully deleted $selectedCount game${selectedCount > 1 ? 's' : ''}.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete games: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(revenueDetailsDateProvider);
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final dateLabel = isToday
        ? "Today"
        : DateFormat('MMM d, yyyy').format(selectedDate);

    final gamesListAsync = ref.watch(selectedDateCompletedPaidGamesProvider);
    final quickSalesListAsync = ref.watch(selectedDateQuickSalesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
        title: Text(_isSelectionMode
            ? "${_selectedGameIds.length} Selected"
            : "Transaction History"),
        centerTitle: false,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _onDeleteSelected(gamesListAsync.asData?.value ?? []),
            ),
        ],
      ),
      body: Column(
        children: [
          DateNavigationHeader(
            selectedDate: selectedDate,
            onDateChanged: (date) {
              ref.read(revenueDetailsDateProvider.notifier).setDate(date);
            },
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Game Transactions Header ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(8),
                        Text(
                          'Game Transactions ($dateLabel)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Game Transactions List ───
                gamesListAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        children: List.generate(
                          2,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: SkeletonLoader(height: 72, borderRadius: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading games: $e'),
                    ),
                  ),
                  data: (games) {
                    if (games.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptySection(
                          theme,
                          isToday
                              ? 'No completed game transactions today.'
                              : 'No completed game transactions on $dateLabel.',
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final session = games[index];
                        return _GameTransactionTile(
                          session: session,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedGameIds.contains(session.id),
                          onSelect: () => _toggleSelection(session.id),
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _enterSelectionMode(session.id);
                            }
                          },
                        );
                      }, childCount: games.length),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: Gap(16)),

                // ─── Quick Sales Transactions Header ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.point_of_sale,
                          size: 18,
                          color: theme.colorScheme.tertiary,
                        ),
                        const Gap(8),
                        Text(
                          'Quick Sale Transactions ($dateLabel)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Quick Sales List ───
                quickSalesListAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        children: List.generate(
                          2,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: SkeletonLoader(height: 72, borderRadius: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading quick sales: $e'),
                    ),
                  ),
                  data: (allSales) {
                    final sales = allSales.toList();
                    if (sales.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptySection(
                          theme,
                          isToday
                              ? 'No paid quick sale transactions today.'
                              : 'No paid quick sale transactions on $dateLabel.',
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sale = sales[index];
                        return _QuickSaleTransactionTile(sale: sale);
                      }, childCount: sales.length),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: Gap(100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(ThemeData theme, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SummarySubitem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _SummarySubitem({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(2),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameTransactionTile extends ConsumerWidget {
  final GameSession session;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;

  const _GameTransactionTile({
    required this.session,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final endTime = session.endTime ?? DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(endTime);
    final players = session.allPlayers.isEmpty
        ? 'No Player Added'
        : session.allPlayers.join(', ');
    final amount = session.finalAmount ?? session.grandTotal ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: onLongPress,
          onTap: () {
            if (isSelectionMode) {
              onSelect();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillDetailsScreen(session: session),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.table_restaurant,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.tableName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (session.isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CANCELLED',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        '$players • ${session.billingType.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              session.isCancelled
                                  ? (session.endedByName != null ? 'Cancelled by ${session.endedByName}' : (session.processedByName != null ? 'Cancelled by ${session.processedByName}' : ''))
                                  : (session.processedByName != null
                                      ? 'Processed by ${session.processedByName}'
                                      : (session.endedByName != null ? 'Ended by ${session.endedByName}' : '')),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session.isCancelled || session.status == TableStatus.cancelled
                                  ? 'Cancelled • $timeStr'
                                  : '${session.paymentMethod?.displayName ?? "Paid"} • $timeStr',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickSaleTransactionTile extends StatelessWidget {
  final QuickSale sale;

  const _QuickSaleTransactionTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('hh:mm a').format(sale.date);
    final customer = sale.customerName?.isNotEmpty == true
        ? sale.customerName!
        : 'Walk-in Customer';
    final itemsStr = sale.items
        .map((i) => '${i.quantity}x ${i.productName}')
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuickSaleDetailsScreen(sale: sale),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customer,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            '₹${sale.totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        itemsStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${sale.paymentMethod.displayName} • $timeStr',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
