import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

/// Financial summary for the dashboard.
///
/// This is a synchronous Provider that aggregates data from multiple
/// upstream StreamProviders. It returns AsyncValue to properly propagate
/// loading/error states.
final financialSummaryProvider = Provider<AsyncValue<RevenueOverviewData>>((ref) {
  // Check if any upstream stream providers are still loading to avoid
  // synchronous rebuilds during the widget build phase (club switch crash).
  final gamesAsync = ref.watch(analyticsGamesStreamProvider);
  final quickSalesAsync = ref.watch(analyticsQuickSalesStreamProvider);
  final paymentsAsync = ref.watch(analyticsPaymentsStreamProvider);
  
  // These are watched internally by getCompleteAnalyticsData.
  // We must ensure they are not loading before evaluating getCompleteAnalyticsData, 
  // otherwise Riverpod throws a setState-during-build exception.
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final customersAsync = ref.watch(allCustomersProvider);

  if (gamesAsync is AsyncLoading || 
      quickSalesAsync is AsyncLoading || 
      paymentsAsync is AsyncLoading ||
      inventoryAsync is AsyncLoading ||
      customersAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (gamesAsync is AsyncError) {
    return AsyncValue.error(gamesAsync.error!, gamesAsync.stackTrace!);
  }

  final data = getCompleteAnalyticsData(ref);
  return AsyncValue.data(data.revenueOverview);
});
