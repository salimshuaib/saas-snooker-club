import re

def fix():
    path = 'lib/features/history/presentation/screens/transaction_history_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the FinancialSummaryCard SliverToBoxAdapter block using regex
    content = re.sub(r'// â”€â”€â”€ Revenue Breakdown Card â”€â”€â”€\s*SliverToBoxAdapter\(\s*child:\s*Padding\(\s*padding:\s*const EdgeInsets\.all\(16\),\s*child:\s*const FinancialSummaryCard\(\s*forSelectedDate:\s*true,\s*isInteractive:\s*false,\s*\),\s*\),\s*\),', '', content, flags=re.DOTALL)
    
    # Remove the import
    content = content.replace("import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';", "")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix()
