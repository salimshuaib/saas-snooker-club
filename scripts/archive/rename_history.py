import os
import re

def update_history():
    file_path = 'lib/features/dashboard/presentation/screens/transaction_history_screen.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace('class TodaysRevenueDetailsScreen', 'class TransactionHistoryScreen')
    content = content.replace('TodaysRevenueDetailsScreen(', 'TransactionHistoryScreen(')
    content = content.replace("title: const Text('Revenue Details')", "title: const Text('Transaction History')")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # Also we need to move it to `history` folder so it matches my router!
    # Wait, my router imported `package:snooker_club/features/history/presentation/screens/transaction_history_screen.dart`
    # Let me just move the file there.
    
if __name__ == '__main__':
    update_history()
