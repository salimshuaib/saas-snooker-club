import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/credit/data/credit_repository.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return CreditRepository(FirebaseFirestore.instance, ref: ref, clubId: clubId);
});

final allCustomersProvider = StreamProvider<List<PlayerProfile>>((ref) {
  final repo = ref.watch(creditRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllCustomers();
});

final pendingTransactionsProvider = StreamProvider.autoDispose
    .family<List<CreditTransaction>, String>((ref, customerId) {
      final repo = ref.watch(creditRepositoryProvider);
      if (repo.clubId == null) return const Stream.empty();
      return repo.watchPendingTransactions(customerId);
    });

final allTransactionsProvider = StreamProvider.autoDispose
    .family<List<CreditTransaction>, String>((ref, customerId) {
      final repo = ref.watch(creditRepositoryProvider);
      if (repo.clubId == null) return const Stream.empty();
      return repo.watchAllTransactions(customerId);
    });

final paymentHistoryProvider = StreamProvider.autoDispose
    .family<List<PaymentHistory>, String>((ref, customerId) {
      final repo = ref.watch(creditRepositoryProvider);
      if (repo.clubId == null) return const Stream.empty();
      return repo.watchPaymentHistory(customerId);
    });

final totalOutstandingCreditProvider = Provider<double>((ref) {
  final customersAsync = ref.watch(allCustomersProvider);
  return customersAsync.maybeWhen(
    data: (customers) => customers.fold(
      0.0,
      (total, customer) => total + customer.outstandingAmount,
    ),
    orElse: () => 0.0,
  );
});

final creditControllerProvider =
    NotifierProvider<CreditController, AsyncValue<void>>(CreditController.new);

class CreditController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> processPayment({
    required PlayerProfile customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(creditRepositoryProvider)
          .processPayment(
            customer: customer,
            paymentAmount: paymentAmount,
            paymentMethod: paymentMethod,
            employeeName: employeeName,
            isFullPayment: isFullPayment,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteMultipleCustomers(Set<String> customerIds) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(creditRepositoryProvider);
      for (final id in customerIds) {
        await repo.deletePlayerProfile(id);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(creditRepositoryProvider).deletePlayerProfile(customerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> mergeCustomers(String sourceId, String targetId) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(creditRepositoryProvider)
          .mergeCustomers(sourceId, targetId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// --- Global Transactions Filtering Providers ---

class GlobalCreditDateFilter extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void updateDate(DateTime? val) => state = val;
}

final globalCreditDateFilterProvider =
    NotifierProvider<GlobalCreditDateFilter, DateTime?>(
      GlobalCreditDateFilter.new,
    );

class GlobalCreditSearch extends Notifier<String> {
  @override
  String build() => '';
  void updateSearch(String val) => state = val;
}

final globalCreditSearchProvider = NotifierProvider<GlobalCreditSearch, String>(
  GlobalCreditSearch.new,
);

final globalRawTransactionsProvider = StreamProvider<List<CreditTransaction>>((
  ref,
) {
  final selectedDate = ref.watch(globalCreditDateFilterProvider);
  final repo = ref.watch(creditRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllTransactionsGlobal(selectedDate);
});

final globalFilteredTransactionsProvider =
    Provider<AsyncValue<List<CreditTransaction>>>((ref) {
      final asyncRaw = ref.watch(globalRawTransactionsProvider);
      final searchQuery = ref.watch(globalCreditSearchProvider).toLowerCase();
      final allCustomersAsync = ref.watch(allCustomersProvider);

      if (asyncRaw is AsyncLoading ||
          (searchQuery.isNotEmpty && allCustomersAsync is AsyncLoading)) {
        return const AsyncValue.loading();
      }

      return asyncRaw.whenData((transactions) {
        if (searchQuery.isEmpty) return transactions;

        final allCustomers = allCustomersAsync.value ?? [];
        return transactions.where((tx) {
          final customer = allCustomers.firstWhere(
            (c) => c.id == tx.customerId,
            orElse: () => PlayerProfile(
              id: '',
              name: '',
              lastTransactionDate: DateTime.now(),
            ),
          );
          final customerNameMatch = customer.name.toLowerCase().contains(
            searchQuery,
          );
          final titleMatch = tx.title.toLowerCase().contains(searchQuery);
          final subtitleMatch = (tx.subtitle ?? '').toLowerCase().contains(
            searchQuery,
          );
          final idMatch = tx.id.toLowerCase().contains(searchQuery);
          final referenceMatch = tx.referenceId.toLowerCase().contains(
            searchQuery,
          );

          return customerNameMatch ||
              titleMatch ||
              subtitleMatch ||
              idMatch ||
              referenceMatch;
        }).toList();
      });
    });

class CustomerSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }

  void clear() => state = {};
}

final customerSelectionProvider =
    NotifierProvider<CustomerSelectionNotifier, Set<String>>(
      CustomerSelectionNotifier.new,
    );

final todayCreditReceivedProvider = StreamProvider<double>((ref) {
  final repo = ref.watch(creditRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();

  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  return repo.watchAllPaymentsByDate(dateStr).map((payments) {
    return payments.fold(0.0, (sum, p) => sum + p.amountPaid);
  });
});
