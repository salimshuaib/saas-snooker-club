import 'package:flutter/material.dart';
import 'package:snooker_club/features/games/presentation/screens/game_activity_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sales_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/new_quick_sale_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sale_details_screen.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:snooker_club/features/authentication/presentation/screens/login_screen.dart';
import 'package:snooker_club/features/authentication/presentation/screens/onboarding_screen.dart';
import 'package:snooker_club/features/authentication/presentation/screens/splash_screen.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/features/updater/presentation/screens/force_update_screen.dart';

import 'package:snooker_club/features/credit/presentation/screens/credit_screen.dart';
import 'package:snooker_club/features/credit/presentation/screens/player_profile_screen.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:snooker_club/features/bookings/presentation/screens/booking_management_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/financial_review_screen.dart';
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

import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/subscription/presentation/screens/no_club_screen.dart';
import 'package:snooker_club/features/subscription/presentation/screens/subscription_expired_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _liveNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'live',
);
final GlobalKey<NavigatorState> _quickSalesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'quickSales');
final GlobalKey<NavigatorState> _historyNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'history');
final GlobalKey<NavigatorState> _khataNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'khata',
);
final GlobalKey<NavigatorState> _dashboardNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');

class RouterNotifier extends ChangeNotifier {
  bool _isScheduled = false;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => _scheduleNotify());
    _ref.listen(currentStaffProvider, (_, __) => _scheduleNotify());
    _ref.listen(updateStateProvider, (_, __) => _scheduleNotify());
    _ref.listen(userClubProvider, (_, __) => _scheduleNotify());
    _ref.listen(clubProfileProvider, (_, __) => _scheduleNotify());
  }

  final Ref _ref;

  void _scheduleNotify() {
    if (!_isScheduled) {
      _isScheduled = true;
      Future.microtask(() {
        _isScheduled = false;
        notifyListeners();
      });
    }
  }
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
      final userClubState = ref.read(userClubProvider);
      final clubProfileState = ref.read(clubProfileProvider);

      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnLogin = state.matchedLocation == RouteNames.login;
      final isOnForceUpdate = state.matchedLocation == RouteNames.forceUpdate;
      final isOnNoClub = state.matchedLocation == RouteNames.noClub;
      final isOnSubscriptionExpired =
          state.matchedLocation == RouteNames.subscriptionExpired;
      final isOnOnboarding = state.matchedLocation == RouteNames.onboarding;

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

      if (!isLoggedIn && !isOnLogin) return RouteNames.login;
      if (!isLoggedIn) return null; // allow login screen

      // Check Club Assignment
      if (userClubState.isLoading) return isOnSplash ? null : RouteNames.splash;
      final userClub = userClubState.value;
      if (userClub == null) {
        return isOnNoClub ? null : RouteNames.noClub;
      }

      // Check Club Profile (Subscription & Onboarding)
      if (clubProfileState.isLoading)
        return isOnSplash ? null : RouteNames.splash;
      final clubProfile = clubProfileState.value;
      if (clubProfile != null && !clubProfile.isActive) {
        return isOnSubscriptionExpired ? null : RouteNames.subscriptionExpired;
      }
      if (clubProfile != null && !clubProfile.isOnboarded) {
        return isOnOnboarding ? null : RouteNames.onboarding;
      }

      if (isOnSplash ||
          isOnLogin ||
          isOnNoClub ||
          isOnSubscriptionExpired ||
          isOnOnboarding) {
        return RouteNames.live;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: RouteNames.subscriptionExpired,
        builder: (context, state) => const TickerMode(
          enabled: true,
          child: const SubscriptionExpiredScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.noClub,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const NoClubScreen()),
      ),
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.team,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const TeamScreen()),
      ),
      GoRoute(
        path: RouteNames.forceUpdate,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const ForceUpdateScreen()),
      ),
      GoRoute(
        path: RouteNames.financialReview,
        builder: (context, state) => const TickerMode(
          enabled: true,
          child: const FinancialReviewScreen(),
        ),
      ),

      // â”€â”€â”€ Bottom Navigation Shell â”€â”€â”€
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
                builder: (context, state) => const TickerMode(
                  enabled: true,
                  child: GameActivityScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Quick Sales
          StatefulShellBranch(
            navigatorKey: _quickSalesNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.quickSales,
                builder: (context, state) =>
                    const TickerMode(enabled: true, child: QuickSalesScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const TickerMode(
                      enabled: true,
                      child: NewQuickSaleScreen(),
                    ),
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

          // Branch: Khata
          StatefulShellBranch(
            navigatorKey: _khataNavigatorKey,
            routes: [
              GoRoute(
                path: RouteNames.khata,
                builder: (context, state) =>
                    const TickerMode(enabled: true, child: CreditScreen()),
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

          // Branch 3: Dashboard
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
        ],
      ),
      GoRoute(
        path: RouteNames.bookings,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: BookingManagementScreen()),
      ),
      GoRoute(
        path: RouteNames.games,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const GamesScreen()),
        routes: [
          GoRoute(
            path: 'table',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final table = extra['table'] as TableModel?;
              final selectedDate =
                  extra['selectedDate'] as DateTime? ?? DateTime.now();
              final isToday = extra['isToday'] as bool? ?? true;
              if (table == null) {
                return const Scaffold(
                  body: Center(child: Text('Table not found.')),
                );
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
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const InventoryScreen()),
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
            builder: (context, state) => const TickerMode(
              enabled: true,
              child: const InventoryHistoryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.more,
        builder: (context, state) =>
            const TickerMode(enabled: true, child: const MoreScreen()),
        routes: [
          GoRoute(
            path: 'analytics',
            builder: (context, state) =>
                const TickerMode(enabled: true, child: const AnalyticsScreen()),
          ),
          GoRoute(
            path: 'credit',
            builder: (context, state) =>
                const TickerMode(enabled: true, child: const CreditScreen()),
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
            builder: (context, state) =>
                const TickerMode(enabled: true, child: const ReportsScreen()),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) =>
                const TickerMode(enabled: true, child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
