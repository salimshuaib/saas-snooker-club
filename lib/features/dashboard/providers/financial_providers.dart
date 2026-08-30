import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

final financialSummaryProvider = Provider<AsyncValue<RevenueOverviewData>>((ref) {
  // Check if any upstream stream providers are still loading to avoid
  // synchronous rebuilds during the widget build phase (club switch crash).
  final gamesAsync = ref.watch(analyticsGamesStreamProvider);
  final quickSalesAsync = ref.watch(analyticsQuickSalesStreamProvider);
  final paymentsAsync = ref.watch(analyticsPaymentsStreamProvider);

  if (gamesAsync is AsyncLoading || quickSalesAsync is AsyncLoading || paymentsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (gamesAsync is AsyncError) {
    return AsyncValue.error(gamesAsync.error!, gamesAsync.stackTrace!);
  }

  final data = getCompleteAnalyticsData(ref);
  return AsyncValue.data(data.revenueOverview);
});
