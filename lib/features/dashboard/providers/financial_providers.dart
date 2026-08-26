import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

final financialSummaryProvider = Provider<AsyncValue<RevenueOverviewData>>((ref) {
  final data = ref.watch(completeAnalyticsProvider);
  return AsyncValue.data(data.revenueOverview);
});
