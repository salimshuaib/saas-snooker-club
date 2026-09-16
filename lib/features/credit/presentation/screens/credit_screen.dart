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
import 'package:snooker_club/features/credit/presentation/widgets/customer_card.dart';
import 'package:snooker_club/features/credit/presentation/widgets/add_manual_credit_sheet.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final allCustomersAsync = ref.watch(allCustomersProvider);
    final selectedIds = ref.watch(customerSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: selectedIds.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    ref.read(customerSelectionProvider.notifier).clear(),
              )
            : null,
        title: Text(
          selectedIds.isNotEmpty
              ? '${selectedIds.length} Selected'
              : 'Khata Profile',
        ),
        actions: [
          if (selectedIds.isEmpty)
            IconButton(
              icon: const Icon(Icons.add_card),
              tooltip: 'Add Manual Khata',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => const AddManualCreditSheet(),
                );
              },
            ),
          if (selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () async {
                final verified = await AdminPasscodeDialog.verify(
                  context,
                  ref,
                  subtitle:
                      'Enter administrator passcode to delete ${selectedIds.length} profile(s).',
                  actionLabel: 'Delete',
                  isDestructive: true,
                );
                if (verified != true || !context.mounted) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Profiles?'),
                    content: Text(
                      'Are you sure you want to completely delete ${selectedIds.length} player(s) and all their credit history? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await Future.delayed(const Duration(milliseconds: 400));
                  await ref
                      .read(creditControllerProvider.notifier)
                      .deleteMultipleCustomers(selectedIds);
                  ref.read(customerSelectionProvider.notifier).clear();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const _KhataGlobalHeader(),
          Expanded(
            child: _CustomersBody(
              currency: currency,
              customersAsync: allCustomersAsync,
              selectedIds: selectedIds,
            ),
          ),
        ],
      ),
    );
  }
}

class _KhataGlobalHeader extends ConsumerWidget {
  const _KhataGlobalHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final customersAsync = ref.watch(allCustomersProvider);
    final todayReceivedAsync = ref.watch(todayCreditReceivedProvider);

    return customersAsync.maybeWhen(
      data: (allCustomers) {
        final totalOutstanding = allCustomers.fold(
          0.0,
          (sum, c) => sum + c.outstandingAmount,
        );
        final pendingPlayers = allCustomers
            .where((c) => c.outstandingAmount > 0)
            .length;
        final todayReceived = todayReceivedAsync.value ?? 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Outstanding',
                  value: CurrencyHelper.formatWhole(totalOutstanding, currency),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.error,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Recv Today',
                  value: CurrencyHelper.formatWhole(todayReceived, currency),
                  icon: Icons.download_done,
                  color: AppColors.success,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Pending',
                  value: '${pendingPlayers}',
                  icon: Icons.people,
                  color: AppColors.warning,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const Gap(4),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CustomersBody extends ConsumerStatefulWidget {
  final Currency currency;
  final AsyncValue<List<PlayerProfile>> customersAsync;
  final Set<String> selectedIds;
  const _CustomersBody({
    required this.currency,
    required this.customersAsync,
    required this.selectedIds,
  });

  @override
  ConsumerState<_CustomersBody> createState() => _CustomersBodyState();
}

class _CustomersBodyState extends ConsumerState<_CustomersBody> {
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
          final matchesSearch = c.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final hasCredit =
              c.outstandingAmount > 0 || c.totalPendingTransactions > 0;
          return matchesSearch && hasCredit;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Khata customers...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                onChanged: (val) =>
                    _debouncer.run(() => setState(() => _searchQuery = val)),
              ),
            ),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'No Khata records found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected = widget.selectedIds.contains(
                          customer.id,
                        );
                        return CustomerCard(
                          customer: customer,
                          currency: widget.currency,
                          isSelected: isSelected,
                          isSelectionMode: isSelectionMode,
                          onToggle: () => ref
                              .read(customerSelectionProvider.notifier)
                              .toggle(customer.id),
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
