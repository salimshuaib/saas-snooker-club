import os

def rewrite_router():
    content = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:snooker_club/features/authentication/presentation/screens/login_screen.dart';
import 'package:snooker_club/features/authentication/presentation/screens/splash_screen.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/features/updater/presentation/screens/force_update_screen.dart';

import 'package:snooker_club/features/credit/presentation/screens/credit_screen.dart';
import 'package:snooker_club/features/credit/presentation/screens/player_profile_screen.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/main_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/more_screen.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/screens/games_screen.dart';
import 'package:snooker_club/features/games/presentation/screens/table_details_screen.dart';
import 'package:snooker_club/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:snooker_club/features/inventory/presentation/screens/product_details_screen.dart';
import 'package:snooker_club/features/inventory/presentation/screens/inventory_history_screen.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sales_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/reports/presentation/screens/reports_screen.dart';
import 'package:snooker_club/features/settings/presentation/screens/settings_screen.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/presentation/screens/team_screen.dart';
import 'package:snooker_club/features/history/presentation/screens/transaction_history_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _dashboardNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final GlobalKey<NavigatorState> _historyNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'history');

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      Future.microtask(() => notifyListeners());
    });
    _ref.listen(currentStaffProvider, (_, __) {
      Future.microtask(() => notifyListeners());
    });
    _ref.listen(updateStateProvider, (_, __) {
      Future.microtask(() => notifyListeners());
    });
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final updateState = ref.read(updateStateProvider);
      final staffState = ref.read(currentStaffProvider);
      
      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnLogin = state.matchedLocation == RouteNames.login;
      final isOnForceUpdate = state.matchedLocation == RouteNames.forceUpdate;

      if (updateState.isForceUpdateRequired) {
        return isOnForceUpdate ? null : RouteNames.forceUpdate;
      }
      if (isOnForceUpdate && !updateState.isForceUpdateRequired) {
        return RouteNames.splash;
      }

      if (authState.isLoading) return isOnSplash ? null : RouteNames.splash;

      final isLoggedIn = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      if (isOnSplash) return null;
      if (!isLoggedIn && !isOnLogin) return RouteNames.login;
      if (isLoggedIn && isOnLogin) return RouteNames.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.team,
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: RouteNames.forceUpdate,
        builder: (context, state) => const ForceUpdateScreen(),
      ),

      // â”€â”€ Bottom Navigation Shell â”€â”€
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
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: History
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const TransactionHistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.games,
        builder: (context, state) => const GamesScreen(),
        routes: [
          GoRoute(
            path: 'table',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final table = extra['table'] as TableModel?;
              final selectedDate = extra['selectedDate'] as DateTime? ?? DateTime.now();
              final isToday = extra['isToday'] as bool? ?? true;
              if (table == null) {
                return const Scaffold(body: Center(child: Text('Table not found.')));
              }
              return TableDetailsScreen(
                table: table,
                selectedDate: selectedDate,
                isToday: isToday,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.inventory,
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'inventory-details',
            builder: (context, state) {
              final item = state.extra as InventoryItem;
              return ProductDetailsScreen(item: item);
            },
          ),
          GoRoute(
            path: 'inventory-history',
            builder: (context, state) => const InventoryHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.more,
        builder: (context, state) => const MoreScreen(),
        routes: [
          GoRoute(
            path: 'quick-sales',
            builder: (context, state) => const QuickSalesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewQuickSaleScreen(),
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
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: 'credit',
            builder: (context, state) => const CreditScreen(),
            routes: [
              GoRoute(
                path: 'details',
                builder: (context, state) {
                  final customer = state.extra as PlayerProfile;
                  return PlayerProfileScreen(customer: customer);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
"""
    with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    rewrite_router()
