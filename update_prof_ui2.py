import re

def update_profile_ui2():
    path = 'lib/features/credit/presentation/screens/player_profile_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    idx = content.find('class _PaymentsTab')
    if idx != -1:
        end_idx = content.find('class _PaymentSheet', idx)
        if end_idx != -1:
            old_payments_tab = content[idx:end_idx]
            
            new_transactions_tab = """class _TransactionsTab extends ConsumerWidget {
  final String customerId;
  final dynamic currency;
  const _TransactionsTab({required this.customerId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider(customerId));
    
    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading transactions: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No transaction history.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCreditGiven = tx.status == CreditTransactionStatus.pending || tx.status == CreditTransactionStatus.partiallyPaid;
            
            final icon = isCreditGiven ? Icons.arrow_upward : Icons.arrow_downward;
            final color = isCreditGiven ? AppColors.error : AppColors.success;
            
            String mainTitle = '';
            if (isCreditGiven) {
              mainTitle = 'Credit Given';
            } else {
              mainTitle = 'Payment Received';
            }
            
            String subTitle = tx.title;
            if (tx.paymentMethod != null) {
              subTitle += ' • ${tx.paymentMethod!.displayName}';
            }
            if (tx.subtitle != null) {
              subTitle += '\\n${tx.subtitle}';
            }
            subTitle += '\\n${DateFormat('MMM d, yyyy - h:mm a').format(tx.date)}';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                isThreeLine: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subTitle),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.format(tx.amount, currency),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isCreditGiven)
                      const Text(
                        'Pending',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      )
                    else
                      const Text(
                        'Paid',
                        style: TextStyle(color: AppColors.success, fontSize: 12),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

"""
            content = content.replace(old_payments_tab, new_transactions_tab)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_profile_ui2()
