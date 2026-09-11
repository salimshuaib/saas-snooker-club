import sys

with open('lib/core/routes/app_router.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []

imports_added = False
skip_mode = False

i = 0
while i < len(lines):
    line = lines[i]

    if not imports_added and line.startswith("import 'package:flutter/material.dart';"):
        new_lines.append(line)
        new_lines.append("import 'package:snooker_club/features/games/presentation/screens/game_activity_screen.dart';\n")
        new_lines.append("import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sales_screen.dart';\n")
        new_lines.append("import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';\n")
        new_lines.append("import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';\n")
        new_lines.append("import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';\n")
        imports_added = True
        i += 1
        continue
        
    if "final GlobalKey<NavigatorState> _dashboardNavigatorKey =" in line:
        new_lines.append("final GlobalKey<NavigatorState> _liveNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'live');\n")
        new_lines.append("final GlobalKey<NavigatorState> _quickSalesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'quickSales');\n")
        new_lines.append("final GlobalKey<NavigatorState> _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');\n")
        new_lines.append("final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');\n")
        i += 4 # skip the next lines defining dashboard and history
        continue

    if "StatefulShellRoute.indexedStack(" in line:
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
      ),
'''
        new_lines.append(new_branches)
        
        # skip lines until the next GoRoute after branches
        while "GoRoute(" not in lines[i+1] or "RouteNames.bookings" not in lines[i+2]:
            i += 1
        i += 1
        continue
        
    if "path: 'quick-sales'," in line:
        # Skip the nested quick-sales route inside more
        # It ends after 16 lines
        i += 17
        continue

    new_lines.append(line)
    i += 1

with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
