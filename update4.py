import re

def fix():
    path = 'lib/features/history/presentation/screens/transaction_history_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to match SliverToBoxAdapter containing FinancialSummaryCard
    content = re.sub(r'SliverToBoxAdapter\(\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(16\),\s*child:\s*const FinancialSummaryCard\(\s*forSelectedDate:\s*true,\s*isInteractive:\s*false,\s*\),\s*\),\s*\),', '', content)
    
    # Also clear the line with the weird characters
    content = re.sub(r'// .*Revenue Breakdown Card.*', '', content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix()
