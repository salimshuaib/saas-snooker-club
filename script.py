import sys

with open('lib/core/routes/app_router.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add imports
imports = '''import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sales_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:flutter/material.dart';'''
if 'quick_sales_screen.dart' not in text:
    text = text.replace("import 'package:flutter/material.dart';", imports)

# 2. Update keys
old_keys = '''final GlobalKey<NavigatorState> _dashboardNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  final GlobalKey<NavigatorState> _historyNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'history');'''

new_keys = '''final GlobalKey<NavigatorState> _liveNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'live');
  final GlobalKey<NavigatorState> _quickSalesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'quickSales');
  final GlobalKey<NavigatorState> _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');
  final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');'''
text = text.replace(old_keys, new_keys)

# 3. Update indexedStack
old_stack = '''      // ─── Bottom Navigation Shell ───
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const TickerMode(enabled: true, child: const DashboardScreen()),
              ),
            ],
          ),

          // Branch 1: History
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (context, state) => const TickerMode(enabled: true, child: const TransactionHistoryScreen()),
              ),
            ],
          ),
        ],
      ),'''

new_stack = '''      // ─── Bottom Navigation Shell ───
      StatefulShellRoute.indexedStack(
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
                builder: (context, state) => const TickerMode(enabled: true, child: Scaffold(body: Center(child: Text('Live')))),
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
text = text.replace(old_stack, new_stack)

# 4. Remove quick sales from more
old_qs = '''          GoRoute(
            path: 'quick-sales',
            builder: (context, state) => const TickerMode(enabled: true, child: const QuickSalesScreen()),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const TickerMode(enabled: true, child: const NewQuickSaleScreen()),
              ),
              GoRoute(
                path: 'details',
                builder: (context, state) {
                  final sale = state.extra as QuickSale;
                  return QuickSaleDetailsScreen(sale: sale);
                },
              ),
            ],
          ),'''
text = text.replace(old_qs, '')

with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated successfully")
