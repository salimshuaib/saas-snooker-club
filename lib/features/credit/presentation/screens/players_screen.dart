import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:snooker_club/core/utils/debouncer.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/credit/presentation/widgets/customer_card.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

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
          selectedIds.isNotEmpty ? '${selectedIds.length} Selected' : 'Players',
        ),
        actions: [
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
      body: _AllPlayersBody(
        currency: currency,
        customersAsync: allCustomersAsync,
        selectedIds: selectedIds,
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

class _MergeCustomersDialog extends ConsumerStatefulWidget {
  const _MergeCustomersDialog();
  @override
  ConsumerState<_MergeCustomersDialog> createState() =>
      _MergeCustomersDialogState();
}

class _MergeCustomersDialogState extends ConsumerState<_MergeCustomersDialog> {
  PlayerProfile? _source;
  PlayerProfile? _target;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final customersAsync = ref.watch(allCustomersProvider);

    return AlertDialog(
      title: const Text('Merge Customers'),
      content: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) return const Text('No customers available.');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select customer to MERGE (this will be deleted):'),
              const Gap(8),
              DropdownButtonFormField<PlayerProfile>(
                initialValue: _source,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: customers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.name} (${CurrencyHelper.formatWhole(c.outstandingAmount, currency)})',
                        ),
                      ),
                    )
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
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.name} (${CurrencyHelper.formatWhole(c.outstandingAmount, currency)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _target = val),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Text('Error: ${err}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _isProcessing || _source == null || _target == null
              ? null
              : _merge,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Merge'),
        ),
      ],
    );
  }

  Future<void> _merge() async {
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(creditControllerProvider.notifier)
          .mergeCustomers(_source!.id, _target!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customers merged successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merge failed: ${e}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _AllPlayersBody extends ConsumerStatefulWidget {
  final Currency currency;
  final AsyncValue<List<PlayerProfile>> customersAsync;
  final Set<String> selectedIds;
  const _AllPlayersBody({
    required this.currency,
    required this.customersAsync,
    required this.selectedIds,
  });

  @override
  ConsumerState<_AllPlayersBody> createState() => _AllPlayersBodyState();
}

class _AllPlayersBodyState extends ConsumerState<_AllPlayersBody> {
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
                        'No players found.',
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
