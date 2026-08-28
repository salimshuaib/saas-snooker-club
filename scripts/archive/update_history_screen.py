import os

def rewrite_history():
    path = 'lib/features/history/presentation/screens/transaction_history_screen.dart'
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Replace the AppBar title
    content = content.replace('title: Text("Revenue Details ($dateLabel)"),', 'title: const Text("Transaction History"),')
    
    # Remove the FinancialSummaryCard section
    sliver_financial_card = """                // â”€â”€â”€ Revenue Breakdown Card â”€â”€â”€
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: const FinancialSummaryCard(
                      forSelectedDate: true,
                      isInteractive: false,
                    ),
                  ),
                ),"""
    
    content = content.replace(sliver_financial_card, '')
    
    # Also remove the unneeded variables like gamesRev and quickSalesRev at the top
    vars_to_remove = """    final gamesRevAsync = ref.watch(selectedDateGamesRevenueStreamProvider);
    final quickSalesRev = ref.watch(selectedDateQuickSalesRevenueProvider);
    final gamesListAsync = ref.watch(selectedDateCompletedPaidGamesProvider);
    final quickSalesListAsync = ref.watch(selectedDateQuickSalesStreamProvider);

    final gamesRev = gamesRevAsync.value ?? 0.0;
    final totalRev = gamesRev + quickSalesRev;"""
    
    vars_replacement = """    final gamesListAsync = ref.watch(selectedDateCompletedPaidGamesProvider);
    final quickSalesListAsync = ref.watch(selectedDateQuickSalesStreamProvider);"""
    
    content = content.replace(vars_to_remove, vars_replacement)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    rewrite_history()
