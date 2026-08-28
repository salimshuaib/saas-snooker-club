import re

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Remove the broken part
idx = code.find("class _MergeCustomersDialog extends ConsumerStatefulWidget {' in line:")
if idx != -1:
    code = code[:idx]

header = '''
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
                  title: 'Total Players',
                  value: f'\',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Credit Customers',
                  value: f'\',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.warning,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Cleared Customers',
                  value: f'\',
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
'''
header = header.replace("f'\$", "'$")

all_players_tab = '''
class _AllPlayersTab extends ConsumerStatefulWidget {
  const _AllPlayersTab();

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
    final currency = ref.watch(currencyProvider);
    final customersAsync = ref.watch(allCustomersProvider);

    return customersAsync.when(
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
                        return _CustomerCard(customer: customer, currency: currency);
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
      error: (err, stack) => Center(child: Text(f'Error: \')),
    );
  }
}
'''
all_players_tab = all_players_tab.replace("f'Error: \$", "'Error: $")


merge_dialog = '''
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
                value: _source,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(f'\ (\)'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _source = val),
              ),
              const Gap(16),
              const Text('Merge TO (balances will combine):'),
              const Gap(8),
              DropdownButtonFormField<PlayerProfile>(
                value: _target,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: customers
                    .where((c) => c.id != _source?.id)
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(f'\ (\)'),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _target = val),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Text(f'Error: \'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
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
          SnackBar(content: Text(f'Merge failed: \'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
'''
merge_dialog = merge_dialog.replace("f'\$", "'$").replace("f'Error: \$", "'Error: $").replace("f'Merge failed: \$", "'Merge failed: $")

code += merge_dialog + header + all_players_tab

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Appended successfully")
