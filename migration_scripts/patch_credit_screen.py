import re

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

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
                  value: '\',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Credit Customers',
                  value: '\',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.warning,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _SummaryCard(
                  title: 'Cleared Customers',
                  value: '\',
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

new_build = '''  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Player Profile'),
          actions: [
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
                Tab(text: 'Player Profile'),
                Tab(text: 'Customer Ledger'),
                Tab(text: 'All Transactions'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _AllPlayersTab(),
                  _CustomersTab(),
                  _GlobalTransactionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }'''

code = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\n  void _showMergeDialog', new_build + r'\n\n  void _showMergeDialog', code, flags=re.DOTALL)

# Now remove the old summary cards from _CustomersTab
customers_tab_cards = r'''            Padding\(
              padding: const EdgeInsets\.all\(16\),
              child: Row\(
                children: \[
                  Expanded\(
                    child: _SummaryCard\(
                      title: 'Total Outstanding',
                      value: CurrencyHelper\.formatWhole\(totalOutstanding, currency\),
                      icon: Icons\.account_balance_wallet,
                      color: AppColors\.error,
                    \),
                  \),
                  const Gap\(12\),
                  Expanded\(
                    child: _SummaryCard\(
                      title: 'Active Customers',
                      value: '\$\{activeCustomers\.length\}',
                      icon: Icons\.people,
                      color: AppColors\.primary,
                    \),
                  \),
                \],
              \),
            \),'''
code = re.sub(customers_tab_cards, '', code, flags=re.DOTALL)

# Add _AllPlayersTab
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
      error: (err, stack) => Center(child: Text('Error: \')),
    );
  }
}
'''

code += header + all_players_tab

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
