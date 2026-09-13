import os

filepath = 'lib/core/routes/app_router.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Extract branches section
start_token = "        branches: ["
end_token = "        ],\n      ),"
start_idx = text.find(start_token)
end_idx = text.find(end_token, start_idx)
branches_text = text[start_idx:end_idx]

# We know the current order: Live, Quick Sales, Khata, History, Dashboard
# Let's just manually replace the entire branches block

new_branches = """        branches: [
          // Branch 0: Live
          StatefulShellBranch(
            navigatorKey: _liveNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.live,
                builder: (context, state) => const TickerMode(
                  enabled: true,
                  child: GameActivityScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Khata
          StatefulShellBranch(
            navigatorKey: _khataNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.khata,
                builder: (context, state) => const TickerMode(
                  enabled: true,
                  child: CreditScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: History
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (context, state) => const TickerMode(
                  enabled: true,
                  child: TransactionHistoryScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Dashboard / Overview
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) =>
                    const TickerMode(enabled: true, child: DashboardScreen()),
              ),
            ],
          ),

          // Branch 4: Quick Sales
          StatefulShellBranch(
            navigatorKey: _quickSalesNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.quickSales,
                builder: (context, state) => const TickerMode(
                  enabled: true,
                  child: QuickSalesScreen(),
                ),
              ),
            ],
          ),"""

text = text.replace(branches_text, new_branches)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
