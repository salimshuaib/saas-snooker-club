import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/quick_sales/data/quick_sales_repository.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

final quickSalesRepositoryProvider = Provider<QuickSalesRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return QuickSalesRepository(
    ref.watch(firestoreServiceProvider).db,
    ref: ref,
    clubId: clubId,
  );
});

final quickSalesDateProvider =
    NotifierProvider<QuickSalesDateNotifier, DateTime>(
      QuickSalesDateNotifier.new,
    );

class QuickSalesDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

final quickSalesProvider = StreamProvider<List<QuickSale>>((ref) {
  final repo = ref.watch(quickSalesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  final date = ref.watch(quickSalesDateProvider);
  return repo.watchQuickSales(date);
});

/// Dedicated stream provider for today's Quick Sales regardless of selected history date.
final todaysQuickSalesStreamProvider = StreamProvider<List<QuickSale>>((ref) {
  final repo = ref.watch(quickSalesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  final now = DateTime.now();
  return repo.watchQuickSales(now);
});

final selectedDateQuickSalesStreamProvider = StreamProvider<List<QuickSale>>((
  ref,
) {
  final repo = ref.watch(quickSalesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  final selectedDate = ref.watch(revenueDetailsDateProvider);
  return repo.watchQuickSales(selectedDate);
});

/// Provider for Today's Quick Sales collected revenue (Cash & UPI only, Credit goes to unpaid accounts).
final todaysQuickSalesRevenueProvider = Provider<double>((ref) {
  final salesAsync = ref.watch(todaysQuickSalesStreamProvider);
  return salesAsync.maybeWhen(
    data: (sales) {
      return sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    },
    orElse: () => 0.0,
  );
});

final selectedDateQuickSalesRevenueProvider = Provider<double>((ref) {
  final salesAsync = ref.watch(selectedDateQuickSalesStreamProvider);
  return salesAsync.maybeWhen(
    data: (sales) {
      return sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    },
    orElse: () => 0.0,
  );
});

/// Provider for counting Today's total completed quick sales.
final todaysQuickSalesCountProvider = Provider<int>((ref) {
  final salesAsync = ref.watch(todaysQuickSalesStreamProvider);
  return salesAsync.maybeWhen(data: (sales) => sales.length, orElse: () => 0);
});

/// A provider for Today's Quick Sales total amount (including credit, used for general volume).
final todaysQuickSalesTotalProvider = Provider<double>((ref) {
  final salesAsync = ref.watch(todaysQuickSalesStreamProvider);
  return salesAsync.maybeWhen(
    data: (sales) => sales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
    orElse: () => 0.0,
  );
});

/// Provider for calculating Quick Sales revenue by a given specific Date string (yyyy-MM-dd) or DateTime.
final dateQuickSalesProvider = StreamProvider.autoDispose
    .family<List<QuickSale>, DateTime>((ref, date) {
      final repo = ref.watch(quickSalesRepositoryProvider);
      if (repo.clubId == null) return const Stream.empty();
      return repo.watchQuickSales(date);
    });
