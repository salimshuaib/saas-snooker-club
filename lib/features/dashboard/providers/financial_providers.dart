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
  // Watch all upstream stream providers unconditionally at the top.
  final gamesAsync = ref.watch(analyticsGamesStreamProvider);
  final quickSalesAsync = ref.watch(analyticsQuickSalesStreamProvider);
  final paymentsAsync = ref.watch(analyticsPaymentsStreamProvider);
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final customersAsync = ref.watch(allCustomersProvider);
  
  final prevGamesAsync = ref.watch(previousGamesStreamProvider);
  final prevQuickSalesAsync = ref.watch(previousQuickSalesStreamProvider);
  final prevPaymentsAsync = ref.watch(previousPaymentsStreamProvider);
  
  // Also watch the synchronous providers used by getCompleteAnalyticsData unconditionally
  ref.watch(analyticsTimeRangeProvider);
  ref.watch(totalOutstandingCreditProvider);

  if (gamesAsync.isLoading || 
      quickSalesAsync.isLoading || 
      paymentsAsync.isLoading ||
      inventoryAsync.isLoading ||
      customersAsync.isLoading ||
      prevGamesAsync.isLoading ||
      prevQuickSalesAsync.isLoading ||
      prevPaymentsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (gamesAsync.hasError) {
    return AsyncValue.error(gamesAsync.error!, gamesAsync.stackTrace!);
  }

  final data = getCompleteAnalyticsData(ref);
  return AsyncValue.data(data.revenueOverview);
});
