import sys

path_ar = 'lib/core/routes/app_router.dart'
with open(path_ar, 'r', encoding='utf-8') as f:
    content_ar = f.read()

old_route = """        builder: (context, state) {
          final customerName = state.extra as String?;
          return TickerMode(enabled: true, child: CombinedSettlementScreen(customerName: customerName ?? 'Unknown'));
        },"""

new_route = """        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          return TickerMode(
            enabled: true,
            child: CombinedSettlementScreen(
              customerId: map['customerId'] as String? ?? 'unknown',
              customerName: map['customerName'] as String? ?? 'Unknown',
              initialBills: map['initialBills'] as List<GameSession>? ?? [],
            ),
          );
        },"""

if old_route in content_ar:
    content_ar = content_ar.replace(old_route, new_route)
    with open(path_ar, 'w', encoding='utf-8') as f:
        f.write(content_ar)
    print("Fixed combinedSettlement router args")
else:
    print("WARNING: Could not find old_route")

