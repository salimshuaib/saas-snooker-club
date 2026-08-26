import re

def rewrite_profile_header():
    path = 'lib/features/credit/presentation/screens/player_profile_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    start_idx = content.find('class _ProfileHeaderCard extends StatelessWidget {')
    if start_idx == -1:
        # maybe it's ConsumerWidget now?
        start_idx = content.find('class _ProfileHeaderCard extends ConsumerWidget {')
    
    end_idx = content.find('    return Container(', start_idx)
    
    if start_idx != -1 and end_idx != -1:
        old_part = content[start_idx:end_idx]
        
        new_part = """class _ProfileHeaderCard extends ConsumerWidget {
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
    
    int totalGames = 0;
    int snookerGames = 0;
    int poolGames = 0;
    
    gamesAsync.whenData((games) {
      totalGames = games.length;
      for (final g in games) {
        if (g.tableType == TableType.snooker) snookerGames++;
        else poolGames++;
      }
    });

    final transactionsAsync = ref.watch(allTransactionsProvider(customer.id));
    
    double totalMoneyPaid = 0;
    transactionsAsync.whenData((txs) {
      for (final tx in txs) {
        if (tx.status == CreditTransactionStatus.paid) {
          totalMoneyPaid += tx.paidAmount;
        }
      }
    });

"""
        content = content.replace(old_part, new_part)
        
    # Also replace "Credit Cleared" text if it's there
    content = content.replace("_StatItem(label: 'Credit Cleared', value: CurrencyHelper.format(totalMoneyPaid, currency)),", "_StatItem(label: 'Total Paid', value: CurrencyHelper.format(totalMoneyPaid, currency)),")
    
    # Check if paymentsAsync is watched in player_profile_screen.dart
    content = content.replace("final paymentsAsync = ref.watch(paymentHistoryProvider(currentCustomer.id));\n", "")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    rewrite_profile_header()
