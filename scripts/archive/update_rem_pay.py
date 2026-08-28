import re

def remove_payments_async():
    path = 'lib/features/credit/presentation/screens/player_profile_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove paymentsAsync from player_profile_screen.dart
    content = content.replace("final paymentsAsync = ref.watch(paymentHistoryProvider(customer.id));", "")
    
    # 2. Remove from _ProfileHeaderCard instantiation
    old_inst = """          _ProfileHeaderCard(
            customer: currentCustomer,
            gamesAsync: gamesAsync,
            quickSalesAsync: quickSalesAsync,
            paymentsAsync: paymentsAsync,
            currency: currency,
          ),"""
    new_inst = """          _ProfileHeaderCard(
            customer: currentCustomer,
            gamesAsync: gamesAsync,
            quickSalesAsync: quickSalesAsync,
            currency: currency,
          ),"""
    content = content.replace(old_inst, new_inst)
    
    # 3. Remove from _ProfileHeaderCard definition
    old_def = """class _ProfileHeaderCard extends StatelessWidget {
  final PlayerProfile customer;
  final AsyncValue<List<GameSession>> gamesAsync;
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final AsyncValue<List<PaymentHistory>> paymentsAsync;
  final dynamic currency;

  const _ProfileHeaderCard({
    required this.customer,
    required this.gamesAsync,
    required this.quickSalesAsync,
    required this.paymentsAsync,
    required this.currency,
  });"""
  
    new_def = """class _ProfileHeaderCard extends StatelessWidget {
  final PlayerProfile customer;
  final AsyncValue<List<GameSession>> gamesAsync;
  final AsyncValue<List<QuickSale>> quickSalesAsync;
  final dynamic currency;

  const _ProfileHeaderCard({
    required this.customer,
    required this.gamesAsync,
    required this.quickSalesAsync,
    required this.currency,
  });"""
    content = content.replace(old_def, new_def)
    
    # 4. Remove the payments accumulation from _ProfileHeaderCard
    old_accum = """    final totalMoneyPaid = paymentsAsync.when(
      data: (payments) => payments.fold(0.0, (sum, p) => sum + p.amountPaid),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );"""
    
    # We will compute totalMoneyPaid from allTransactionsProvider inside the build, but wait! _ProfileHeaderCard is a StatelessWidget and it doesn't watch allTransactionsProvider right now. Let's just make it a ConsumerWidget or leave it as 0.0 for now, or use gamesAsync?
    # Actually, if I look at the mockup:
    # PLAYER FINANCIAL SUMMARY
    # Total Paid to Club       â‚¹8,450
    # Cash Payments            â‚¹2,500
    # UPI Payments             â‚¹4,750
    # Credit Payments          â‚¹1,200
    # Outstanding Credit       â‚¹300
    
    # This implies I should compute from transactions!
    # Let me make _ProfileHeaderCard a ConsumerWidget and compute it!
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    remove_payments_async()
