import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:snooker_club/core/utils/debouncer.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final allCustomersAsync = ref.watch(allCustomersProvider);
    final globalDateFilter = ref.watch(globalCreditDateFilterProvider);
    final globalTransactionsAsync = ref.watch(globalFilteredTransactionsProvider);
    final globalSearchQuery = ref.watch(globalCreditSearchProvider);
    final selectedIds = ref.watch(customerSelectionProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: selectedIds.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(customerSelectionProvider.notifier).clear(),
                )
              : null,
          title: Text(selectedIds.isNotEmpty
              ? '${selectedIds.length} Selected'
              : 'Player Profile'),
          actions: [
            if (selectedIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () async {
                  final verified = await AdminPasscodeDialog.verify(
                    context, ref,
                    subtitle: 'Enter administrator passcode to delete ${selectedIds.length} profile(s).',
                    actionLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (verified != true || !context.mounted) return;
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Profiles?'),
                      content: Text('Are you sure you want to completely delete ${selectedIds.length} player(s) and all their credit history? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await Future.delayed(const Duration(milliseconds: 400));
                    await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                    ref.read(customerSelectionProvider.notifier).clear();
                  }
                },
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  return IconButton(
                    icon: const Icon(Icons.merge_type),
                    tooltip: 'Merge Customers',
                    onPressed: () => _showMergeDialog(context, ref),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            const _PlayerProfileGlobalHeader(),
            const TabBar(
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Players'),
                Tab(text: 'Ledger'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AllPlayersTab(currency: currency, customersAsync: allCustomersAsync, selectedIds: selectedIds),
                  _CustomersTab(currency: currency, customersAsync: allCustomersAsync, selectedIds: selectedIds),
                  _GlobalTransactionsTab(
                    currency: currency,
                    dateFilter: globalDateFilter,
                    transactionsAsync: globalTransactionsAsync,
                    allCustomersAsync: allCustomersAsync,
                    searchQuery: globalSearchQuery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMergeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const _MergeCustomersDialog(),
    );
  }
}

class _CustomersTab extends ConsumerStatefulWidget {
  final Currency currency;
  final AsyncValue<List<PlayerProfile>> customersAsync;
  final Set<String> selectedIds;
  const _CustomersTab({required this.currency, required this.customersAsync, required this.selectedIds});

  @override
  ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionMode = widget.selectedIds.isNotEmpty;

    return widget.customersAsync.when(
      data: (allCustomers) {
        final activeCustomers = allCustomers
            .where((c) => c.outstandingAmount > 0 || c.totalPendingTransactions > 0)
            .toList();
        final filteredCustomers = activeCustomers.where((c) {
          return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                onChanged: (val) => _debouncer.run(() => setState(() => _searchQuery = val)),
              ),
            ),
            const Gap(16),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'No customers found.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected = widget.selectedIds.contains(customer.id);
                        return _CustomerCard(
                          customer: customer, 
                          currency: widget.currency,
                          isSelected: isSelected,
                          isSelectionMode: isSelectionMode,
                          onToggle: () => ref.read(customerSelectionProvider.notifier).toggle(customer.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 80, borderRadius: 12),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _GlobalTransactionsTab extends ConsumerStatefulWidget {
  final Currency currency;
  final DateTime? dateFilter;
  final AsyncValue<List<CreditTransaction>> transactionsAsync;
  final AsyncValue<List<PlayerProfile>> allCustomersAsync;
  final String searchQuery;

  const _GlobalTransactionsTab({
    required this.currency,
    required this.dateFilter,
    required this.transactionsAsync,
    required this.allCustomersAsync,
    required this.searchQuery,
  });

  @override
  ConsumerState<_GlobalTransactionsTab> createState() => _GlobalTransactionsTabState();
}

class _GlobalTransactionsTabState extends ConsumerState<_GlobalTransactionsTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filter Area
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Player / Game...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        _debouncer.run(() {
                          ref.read(globalCreditSearchProvider.notifier).updateSearch(val);
                        });
                      },
                    ),
                  ),
                  const Gap(8),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: widget.dateFilter ?? now,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date != null) {
                        ref.read(globalCreditDateFilterProvider.notifier).updateDate(date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.dateFilter != null ? AppColors.primary : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.dateFilter != null ? AppColors.primary : theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: widget.dateFilter != null ? Colors.white : theme.colorScheme.onSurface,
                          ),
                          const Gap(8),
                          Text(
                            widget.dateFilter != null ? DateFormat('MMM d').format(widget.dateFilter!) : 'Date',
                            style: TextStyle(
                              color: widget.dateFilter != null ? Colors.white : theme.colorScheme.onSurface,
                              fontWeight: widget.dateFilter != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.dateFilter != null || widget.searchQuery.isNotEmpty) ...[
                const Gap(8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(globalCreditSearchProvider.notifier).updateSearch('');
                      ref.read(globalCreditDateFilterProvider.notifier).updateDate(null);
                    },
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.error),
                    label: const Text('Clear Filters', style: TextStyle(color: AppColors.error)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // List Area
        Expanded(
          child: widget.transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Text(
                    'No credit transactions found for the selected filters.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  
                  // Lookup customer name safely
                  final customerName = widget.allCustomersAsync.maybeWhen(
                    data: (customers) {
                      final c = customers.where((c) => c.id == tx.customerId).toList();
                      return c.isNotEmpty ? c.first.name : 'Unknown Player';
                    },
                    orElse: () => 'Loading...',
                  );

                  final dtFmt = DateFormat('MMM d, yyyy - hh:mm a');
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$customerName \u2022 ${tx.title}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          CurrencyHelper.formatWhole(tx.amount, widget.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(4),
                        if (tx.subtitle != null && tx.subtitle!.isNotEmpty) ...[
                          Text(tx.subtitle!, style: theme.textTheme.bodySmall),
                          const Gap(2),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dtFmt.format(tx.date), style: theme.textTheme.bodySmall),
                            if (tx.status != CreditTransactionStatus.pending)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tx.status == CreditTransactionStatus.paid 
                                      ? AppColors.success.withValues(alpha: 0.2) 
                                      : AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tx.status == CreditTransactionStatus.paid 
                                      ? 'PAID' 
                                      : 'PAID ${CurrencyHelper.formatWhole(tx.paidAmount, widget.currency)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tx.status == CreditTransactionStatus.paid ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'UNPAID',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      final customer = widget.allCustomersAsync.value?.firstWhere((c) => c.id == tx.customerId);
                      if (customer != null) {
                        context.push('/more/credit/details', extra: customer);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}


class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Gap(4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final PlayerProfile customer;
  final Currency currency;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggle;

  const _CustomerCard({
    required this.customer, 
    required this.currency,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggle,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  Timer? _timer;
  bool _longPressTriggered = false;

  void _startTimer() {
    if (widget.isSelectionMode) return;
    
    _timer = Timer(const Duration(seconds: 3), () {
      HapticFeedback.heavyImpact();
      _longPressTriggered = true;
      widget.onToggle();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;
    final isSelectionMode = widget.isSelectionMode;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: () => _cancelTimer(),
        onTap: () {
          _cancelTimer();
          if (_longPressTriggered) {
            _longPressTriggered = false;
            return;
          }
          if (isSelectionMode) {
            widget.onToggle();
          } else {
            context.push('/more/credit/details', extra: widget.customer);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Gap(4),
                    Text(
                      'Last updated: ',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatWhole(widget.customer.outstandingAmount, widget.currency),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.customer.outstandingAmount > 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.customer.outstandingAmount > 0 ? 'Outstanding' : 'Cleared',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.customer.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _MergeCustomersDialog extends ConsumerStatefulWidget {
  const _MergeCustomersDialog();

  @override
  ConsumerState<_MergeCustomersDialog> createState() => _MergeCustomersDialogState();
}

class _MergeCustomersDialogState extends ConsumerState<_MergeCustomersDialog> {
  PlayerProfile? _source;
  PlayerProfile? _target;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);
    final currency = ref.watch(currencyProvider);

    return AlertDialog(
      title: const Text('Merge Customers'),
      content: customersAsync.when(
        data: (customers) {
          if (customers.length < 2) {
            return const Text('Not enough customers to merge.');
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Merge FROM (this profile will be deleted):'),
              const Gap(8),
              DropdownButtonFormField<PlayerProfile>(
                initialValue: _source,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${CurrencyHelper.formatWhole(c.outstandingAmount, currency)})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _source = val),
              ),
              const Gap(16),
              const Text('Merge TO (balances will combine):'),
              const Gap(8),
              DropdownButtonFormField<PlayerProfile>(
                initialValue: _target,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: customers
                    .where((c) => c.id != _source?.id)
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} (${CurrencyHelper.formatWhole(c.outstandingAmount, currency)})'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _target = val),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Text('Error: ${err}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _isProcessing || _source == null || _target == null ? null : _merge,
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Merge'),
        ),
      ],
    );
  }

  Future<void> _merge() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(creditControllerProvider.notifier).mergeCustomers(
            _source!.id,
            _target!.id,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customers merged successfully.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge failed: ${e}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _PlayerProfileGlobalHeader extends ConsumerWidget {
  const _PlayerProfileGlobalHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);

    return customersAsync.maybeWhen(
      data: (allCustomers) {
        final totalPlayers = allCustomers.length;
        final creditCustomers = allCustomers.where((c) => c.outstandingAmount > 0 || c.totalPendingTransactions > 0).length;
        final clearedCustomers = allCustomers.where((c) => c.outstandingAmount <= 0 && c.totalPendingTransactions == 0 && c.lastPaymentDate != null).length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total',
                  value: '${totalPlayers}',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Credit',
                  value: '${creditCustomers}',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.warning,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Cleared',
                  value: '${clearedCustomers}',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AllPlayersTab extends ConsumerStatefulWidget {
  final Currency currency;
  final AsyncValue<List<PlayerProfile>> customersAsync;
  final Set<String> selectedIds;
  const _AllPlayersTab({required this.currency, required this.customersAsync, required this.selectedIds});

  @override
  ConsumerState<_AllPlayersTab> createState() => _AllPlayersTabState();
}

class _AllPlayersTabState extends ConsumerState<_AllPlayersTab> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  String _searchQuery = '';

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelectionMode = widget.selectedIds.isNotEmpty;

    return widget.customersAsync.when(
      data: (allCustomers) {
        final filteredCustomers = allCustomers.where((c) {
          return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                onChanged: (val) => _debouncer.run(() => setState(() => _searchQuery = val)),
              ),
            ),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'No players found.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected = widget.selectedIds.contains(customer.id);
                        return _CustomerCard(
                          customer: customer, 
                          currency: widget.currency,
                          isSelected: isSelected,
                          isSelectionMode: isSelectionMode,
                          onToggle: () => ref.read(customerSelectionProvider.notifier).toggle(customer.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, _) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 80, borderRadius: 12),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: ${err}')),
    );
  }
}
