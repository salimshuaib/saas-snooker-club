import os
import re

# 1. Update route_names.dart
filepath = 'lib/core/routes/route_names.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

if 'static const String combinedSettlement =' not in content:
    content = content.replace("static const String pendingBills = 'pending-bills';",
                              "static const String pendingBills = 'pending-bills';\n  static const String combinedSettlement = 'combined-settlement';")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# 2. Update app_router.dart
filepath = 'lib/core/routes/app_router.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:snooker_club/features/games/presentation/screens/combined_settlement_screen.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:snooker_club/features/games/presentation/screens/pending_bills_screen.dart';",
                              "import 'package:snooker_club/features/games/presentation/screens/pending_bills_screen.dart';\n" + import_stmt)

route_code = '''
                GoRoute(
                  path: RouteNames.combinedSettlement,
                  builder: (context, state) {
                    final args = state.extra as Map<String, dynamic>;
                    return CombinedSettlementScreen(
                      customerId: args['customerId'] as String,
                      customerName: args['customerName'] as String,
                      initialBills: args['initialBills'] as List<GameSession>,
                    );
                  },
                ),
'''
if 'path: RouteNames.combinedSettlement,' not in content:
    old_route = '''GoRoute(
                  path: RouteNames.pendingBills,
                  builder: (context, state) => const PendingBillsScreen(),
                ),'''
    new_route = '''GoRoute(
                  path: RouteNames.pendingBills,
                  builder: (context, state) => const PendingBillsScreen(),
                ),''' + route_code
    content = content.replace(old_route, new_route)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


# 3. Update pending_bills_screen.dart
filepath = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_button = '''ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Combined settlement coming in next phase')),
                                    );'''
                                    
new_button = '''context.push(
                                      '${RouteNames.history}/${RouteNames.pendingBills}/${RouteNames.combinedSettlement}',
                                      extra: {
                                        'customerId': customerId,
                                        'customerName': customerName,
                                        'initialBills': customerBills,
                                      },
                                    );'''
                                    
content = content.replace(old_button, new_button)
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Phase 5 complete')
