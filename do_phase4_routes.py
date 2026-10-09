import os
import re

filepath = 'lib/core/routes/route_names.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

if 'static const String pendingBills =' not in content:
    content = content.replace("static const String history = '/history';",
                              "static const String history = '/history';\n  static const String pendingBills = 'pending-bills';")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

filepath = 'lib/core/routes/app_router.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:snooker_club/features/games/presentation/screens/pending_bills_screen.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:snooker_club/features/history/presentation/screens/transaction_history_screen.dart';",
                              "import 'package:snooker_club/features/history/presentation/screens/transaction_history_screen.dart';\n" + import_stmt)

route_code = '''
            GoRoute(
              path: RouteNames.pendingBills,
              builder: (context, state) => const PendingBillsScreen(),
            ),
'''

if 'path: RouteNames.pendingBills,' not in content:
    # We want to add this under history route.
    # The history route is defined as:
    # GoRoute(
    #   path: RouteNames.history,
    #   builder: (context, state) => const TransactionHistoryScreen(),
    # ),
    # Let's replace the builder and add routes.
    old_route = '''GoRoute(
              path: RouteNames.history,
              builder: (context, state) => const TransactionHistoryScreen(),
            ),'''
            
    new_route = '''GoRoute(
              path: RouteNames.history,
              builder: (context, state) => const TransactionHistoryScreen(),
              routes: [
                GoRoute(
                  path: RouteNames.pendingBills,
                  builder: (context, state) => const PendingBillsScreen(),
                ),
              ],
            ),'''
    content = content.replace(old_route, new_route)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated routes')
