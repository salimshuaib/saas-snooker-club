import re

with open('lib/core/routes/app_router.dart', 'r', encoding='utf-8') as f:
    text = f.read()

new_branches = '''      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Live
          StatefulShellBranch(
            navigatorKey: _liveNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.live,
                builder: (context, state) => const TickerMode(enabled: true, child: GameActivityScreen()),
              ),
            ],
          ),
          
          // Branch 1: Quick Sales
          StatefulShellBranch(
            navigatorKey: _quickSalesNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.quickSales,
                builder: (context, state) => const TickerMode(enabled: true, child: QuickSalesScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const TickerMode(enabled: true, child: NewQuickSaleScreen()),
                  ),
                  GoRoute(
                    path: 'details',
                    builder: (context, state) {
                      final sale = state.extra as QuickSale;
                      return QuickSaleDetailsScreen(sale: sale);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: History
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (context, state) => const TickerMode(enabled: true, child: TransactionHistoryScreen()),
              ),
            ],
          ),
          
          // Branch 3: Dashboard
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const TickerMode(enabled: true, child: DashboardScreen()),
              ),
            ],
          ),
        ],
      ),'''
text = re.sub(r'      StatefulShellRoute\.indexedStack\(.*?],\s*\),', new_branches, text, flags=re.DOTALL)

with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(text)
