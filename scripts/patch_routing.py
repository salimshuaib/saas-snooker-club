import sys
import re

# 1. Update RouteNames
path_rn = 'lib/core/routes/route_names.dart'
with open(path_rn, 'r', encoding='utf-8') as f:
    content_rn = f.read()

content_rn = content_rn.replace("static const String pendingBills = 'pending-bills';", "static const String pendingBills = '/pending-bills';")
content_rn = content_rn.replace("static const String combinedSettlement = 'combined-settlement';", "static const String combinedSettlement = '/combined-settlement';")

with open(path_rn, 'w', encoding='utf-8') as f:
    f.write(content_rn)

# 2. Add to AppRouter
path_ar = 'lib/core/routes/app_router.dart'
with open(path_ar, 'r', encoding='utf-8') as f:
    content_ar = f.read()

import_statement = "import 'package:snooker_club/features/games/presentation/screens/pending_bills_screen.dart';\nimport 'package:snooker_club/features/games/presentation/screens/combined_settlement_screen.dart';"
if "pending_bills_screen.dart" not in content_ar:
    content_ar = content_ar.replace("import 'package:snooker_club/features/dashboard/presentation/screens/dashboard_screen.dart';", "import 'package:snooker_club/features/dashboard/presentation/screens/dashboard_screen.dart';\n" + import_statement)

routes_to_add = """      GoRoute(
        path: RouteNames.pendingBills,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: PendingBillsScreen()),
      ),
      GoRoute(
        path: RouteNames.combinedSettlement,
        builder: (context, state) {
          final customerName = state.extra as String?;
          return TickerMode(enabled: true, child: CombinedSettlementScreen(customerName: customerName ?? 'Unknown'));
        },
      ),"""

if "RouteNames.pendingBills," not in content_ar:
    content_ar = content_ar.replace("      GoRoute(\n        path: RouteNames.login,", routes_to_add + "\n      GoRoute(\n        path: RouteNames.login,")

with open(path_ar, 'w', encoding='utf-8') as f:
    f.write(content_ar)

# 3. Update paths in screens
path_pbs = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path_pbs, 'r', encoding='utf-8') as f:
    content_pbs = f.read()
content_pbs = content_pbs.replace("'${RouteNames.history}/${RouteNames.pendingBills}/${RouteNames.combinedSettlement}'", "RouteNames.combinedSettlement")
with open(path_pbs, 'w', encoding='utf-8') as f:
    f.write(content_pbs)

path_bds = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(path_bds, 'r', encoding='utf-8') as f:
    content_bds = f.read()
content_bds = content_bds.replace("'${RouteNames.history}/${RouteNames.pendingBills}/${RouteNames.combinedSettlement}'", "RouteNames.combinedSettlement")
with open(path_bds, 'w', encoding='utf-8') as f:
    f.write(content_bds)

print("All routing patched!")
