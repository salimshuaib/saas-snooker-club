import os

def clean_imports():
    # 1. DashboardScreen
    p = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("import 'package:snooker_club/features/dashboard/presentation/screens/todays_revenue_details_screen.dart';", "")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # 2. FinancialSummaryCard
    p = 'lib/features/dashboard/presentation/widgets/financial_summary_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("import 'package:snooker_club/features/dashboard/presentation/screens/todays_revenue_details_screen.dart';", "import 'package:go_router/go_router.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    clean_imports()
