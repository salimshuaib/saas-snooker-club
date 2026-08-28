import re

def update_profile_header():
    path = 'lib/features/credit/presentation/screens/player_profile_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_def = """class _ProfileHeaderCard extends StatelessWidget {
  final PlayerProfile customer;
  final AsyncValue<List<GameSession>> gamesAsync;
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final dynamic currency;

  const _ProfileHeaderCard({
    required this.customer,
    required this.gamesAsync,
    required this.quickSalesAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGames = gamesAsync.when(
      data: (games) => games.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final snookerGames = gamesAsync.when(
      data: (games) => games.where((g) => g.tableType == TableType.snooker).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final poolGames = gamesAsync.when(
      data: (games) => games.where((g) => g.tableType == TableType.pool).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final totalMoneyPaid = paymentsAsync.when(
      data: (payments) => payments.fold(0.0, (sum, p) => sum + p.amountPaid),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );"""
    
    new_def = """class _ProfileHeaderCard extends ConsumerWidget {
  final PlayerProfile customer;
  final AsyncValue<List<GameSession>> gamesAsync;
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final dynamic currency;

  const _ProfileHeaderCard({
    required this.customer,
    required this.gamesAsync,
    required this.quickSalesAsync,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalGames = gamesAsync.when(
      data: (games) => games.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final snookerGames = gamesAsync.when(
      data: (games) => games.where((g) => g.tableType == TableType.snooker).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final poolGames = gamesAsync.when(
      data: (games) => games.where((g) => g.tableType == TableType.pool || g.tableType == TableType.americanPool).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    
    final transactionsAsync = ref.watch(allTransactionsProvider(customer.id));
    final totalMoneyPaid = transactionsAsync.when(
      data: (transactions) => transactions.where((tx) => tx.status == CreditTransactionStatus.paid).fold(0.0, (sum, tx) => sum + tx.paidAmount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );"""
    content = content.replace(old_def, new_def)
    
    content = content.replace("_StatItem(label: 'Credit Cleared', value: CurrencyHelper.format(totalMoneyPaid, currency)),", "_StatItem(label: 'Total Paid', value: CurrencyHelper.format(totalMoneyPaid, currency)),")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_profile_header()
