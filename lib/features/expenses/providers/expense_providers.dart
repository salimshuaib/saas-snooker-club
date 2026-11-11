import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/expenses/data/expense_repository.dart';
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return ExpenseRepository(ref: ref, clubId: clubId);
});

/// Preset date filter intervals for expenses
enum ExpenseDateFilter {
  today,
  yesterday,
  last7Days,
  thisMonth,
  last6Months,
  oneYear,
  custom,
}

extension ExpenseDateFilterX on ExpenseDateFilter {
  String get label {
    switch (this) {
      case ExpenseDateFilter.today:
        return 'Today';
      case ExpenseDateFilter.yesterday:
        return 'Yesterday';
      case ExpenseDateFilter.last7Days:
        return 'Last 7 Days';
      case ExpenseDateFilter.thisMonth:
        return 'This Month';
      case ExpenseDateFilter.last6Months:
        return 'Last 6 Months';
      case ExpenseDateFilter.oneYear:
        return '1 Year';
      case ExpenseDateFilter.custom:
        return 'Custom';
    }
  }
}

/// Represents the selected date boundary for viewing expenses
class ExpenseDateRange {
  final ExpenseDateFilter filter;
  final DateTime start;
  final DateTime end;

  const ExpenseDateRange({
    required this.filter,
    required this.start,
    required this.end,
  });

  bool get isSingleDay =>
      start.year == end.year && start.month == end.month && start.day == end.day;

  ExpenseDateRange copyWith({
    ExpenseDateFilter? filter,
    DateTime? start,
    DateTime? end,
  }) {
    return ExpenseDateRange(
      filter: filter ?? this.filter,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseDateRange &&
          runtimeType == other.runtimeType &&
          filter == other.filter &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(filter, start, end);
}

/// Notifier to manage the date range for viewing expenses
class ExpenseDateRangeNotifier extends Notifier<ExpenseDateRange> {
  static ExpenseDateRange _rangeForFilter(ExpenseDateFilter filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (filter) {
      case ExpenseDateFilter.today:
        return ExpenseDateRange(
          filter: filter,
          start: todayStart,
          end: todayEnd,
        );
      case ExpenseDateFilter.yesterday:
        final yStart = todayStart.subtract(const Duration(days: 1));
        final yEnd = DateTime(yStart.year, yStart.month, yStart.day, 23, 59, 59, 999);
        return ExpenseDateRange(
          filter: filter,
          start: yStart,
          end: yEnd,
        );
      case ExpenseDateFilter.last7Days:
        final start = todayStart.subtract(const Duration(days: 6));
        return ExpenseDateRange(
          filter: filter,
          start: start,
          end: todayEnd,
        );
      case ExpenseDateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return ExpenseDateRange(
          filter: filter,
          start: start,
          end: end,
        );
      case ExpenseDateFilter.last6Months:
        final start = DateTime(now.year, now.month - 5, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return ExpenseDateRange(
          filter: filter,
          start: start,
          end: end,
        );
      case ExpenseDateFilter.oneYear:
        final start = DateTime(now.year - 1, now.month, now.day);
        return ExpenseDateRange(
          filter: filter,
          start: start,
          end: todayEnd,
        );
      case ExpenseDateFilter.custom:
        return ExpenseDateRange(
          filter: filter,
          start: todayStart,
          end: todayEnd,
        );
    }
  }

  @override
  ExpenseDateRange build() {
    return _rangeForFilter(ExpenseDateFilter.today);
  }

  void setFilter(ExpenseDateFilter filter) {
    state = _rangeForFilter(filter);
  }

  void setCustomRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    state = ExpenseDateRange(
      filter: ExpenseDateFilter.custom,
      start: s,
      end: e,
    );
  }

  void setDate(DateTime date) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final s = DateTime(date.year, date.month, date.day);
    final e = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    ExpenseDateFilter filter = ExpenseDateFilter.custom;
    if (s.year == todayStart.year &&
        s.month == todayStart.month &&
        s.day == todayStart.day) {
      filter = ExpenseDateFilter.today;
    } else if (s.year == yesterdayStart.year &&
        s.month == yesterdayStart.month &&
        s.day == yesterdayStart.day) {
      filter = ExpenseDateFilter.yesterday;
    }

    state = ExpenseDateRange(
      filter: filter,
      start: s,
      end: e,
    );
  }

  void shiftRange(int direction) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    if (direction > 0 &&
        (state.end.isAfter(todayEnd) || state.end.isAtSameMomentAs(todayEnd))) {
      return; // Cannot shift beyond today
    }

    switch (state.filter) {
      case ExpenseDateFilter.today:
      case ExpenseDateFilter.yesterday:
        final newDate = state.start.add(Duration(days: direction));
        final newStart = DateTime(newDate.year, newDate.month, newDate.day);
        final newEnd = DateTime(newDate.year, newDate.month, newDate.day, 23, 59, 59, 999);

        final todayStart = DateTime(now.year, now.month, now.day);
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));

        ExpenseDateFilter newFilter = ExpenseDateFilter.custom;
        if (newStart.year == todayStart.year &&
            newStart.month == todayStart.month &&
            newStart.day == todayStart.day) {
          newFilter = ExpenseDateFilter.today;
        } else if (newStart.year == yesterdayStart.year &&
            newStart.month == yesterdayStart.month &&
            newStart.day == yesterdayStart.day) {
          newFilter = ExpenseDateFilter.yesterday;
        }

        state = ExpenseDateRange(
          filter: newFilter,
          start: newStart,
          end: newEnd,
        );
        break;

      case ExpenseDateFilter.last7Days:
        final newStart = state.start.add(Duration(days: 7 * direction));
        final newEnd = state.end.add(Duration(days: 7 * direction));
        state = ExpenseDateRange(
          filter: ExpenseDateFilter.custom,
          start: newStart,
          end: newEnd,
        );
        break;

      case ExpenseDateFilter.thisMonth:
        final targetMonth =
            DateTime(state.start.year, state.start.month + direction, 1);
        final newStart = DateTime(targetMonth.year, targetMonth.month, 1);
        final newEnd = DateTime(
            targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59, 999);
        final isThisMonth =
            targetMonth.year == now.year && targetMonth.month == now.month;

        state = ExpenseDateRange(
          filter:
              isThisMonth ? ExpenseDateFilter.thisMonth : ExpenseDateFilter.custom,
          start: newStart,
          end: newEnd,
        );
        break;

      case ExpenseDateFilter.last6Months:
        final newStart =
            DateTime(state.start.year, state.start.month + (6 * direction), 1);
        final newEnd = DateTime(state.end.year,
            state.end.month + (6 * direction) + 1, 0, 23, 59, 59, 999);
        state = ExpenseDateRange(
          filter: ExpenseDateFilter.custom,
          start: newStart,
          end: newEnd,
        );
        break;

      case ExpenseDateFilter.oneYear:
        final newStart = DateTime(
            state.start.year + direction, state.start.month, state.start.day);
        final newEnd = DateTime(state.end.year + direction, state.end.month,
            state.end.day, 23, 59, 59, 999);
        state = ExpenseDateRange(
          filter: ExpenseDateFilter.custom,
          start: newStart,
          end: newEnd,
        );
        break;

      case ExpenseDateFilter.custom:
        final diffDays = state.end.difference(state.start).inDays;
        final step = diffDays == 0 ? 1 : diffDays + 1;
        final newStart = state.start.add(Duration(days: step * direction));
        final newEnd = state.end.add(Duration(days: step * direction));
        state = ExpenseDateRange(
          filter: ExpenseDateFilter.custom,
          start: newStart,
          end: newEnd,
        );
        break;
    }
  }
}

/// Provider for active date range filter in expenses
final expenseDateRangeProvider =
    NotifierProvider<ExpenseDateRangeNotifier, ExpenseDateRange>(
  () => ExpenseDateRangeNotifier(),
);

/// Kept for backward compatibility
class SelectedExpenseDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return ref.watch(expenseDateRangeProvider).start;
  }

  void setDate(DateTime date) {
    ref.read(expenseDateRangeProvider.notifier).setDate(date);
  }

  void previousDay() {
    ref.read(expenseDateRangeProvider.notifier).shiftRange(-1);
  }

  void nextDay() {
    ref.read(expenseDateRangeProvider.notifier).shiftRange(1);
  }
}

final selectedExpenseDateProvider =
    NotifierProvider<SelectedExpenseDateNotifier, DateTime>(
  () => SelectedExpenseDateNotifier(),
);

/// Stream of expenses for a specific date
final expensesForDateStreamProvider =
    StreamProvider.family<List<Expense>, DateTime>((ref, date) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  return repo.watchExpenses(date);
});

/// Stream of expenses for the currently selected date range
final expensesForSelectedDateProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  final dateRange = ref.watch(expenseDateRangeProvider);
  return repo.watchExpensesByDateRange(dateRange.start, dateRange.end);
});

/// Stream of expenses matching the analytics time range
final analyticsExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  final timeRange = ref.watch(analyticsTimeRangeProvider);
  return repo.watchExpensesByDateRange(timeRange.start, timeRange.end);
});

/// Stream of all business credit based transactions
final businessCreditExpensesStreamProvider =
    StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo.clubId == null) return Stream.value([]);
  return repo.watchBusinessCreditExpenses();
});

/// Count of outstanding (unsettled) business credit transactions
final unsettledBusinessCreditCountProvider = Provider<int>((ref) {
  final creditExpenses =
      ref.watch(businessCreditExpensesStreamProvider).value ?? [];
  return creditExpenses.where((e) => e.isOutstandingCredit).length;
});

/// Total amount of outstanding business credit
final totalOutstandingBusinessCreditProvider = Provider<double>((ref) {
  final creditExpenses =
      ref.watch(businessCreditExpensesStreamProvider).value ?? [];
  return creditExpenses
      .where((e) => e.isOutstandingCredit)
      .fold<double>(0.0, (sum, e) => sum + e.amount);
});

/// Today's expenses sum
final todaysExpensesTotalProvider = StreamProvider<double>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo.clubId == null) return Stream.value(0.0);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return repo.watchExpenses(today).map(
    (expenses) => expenses.fold<double>(0.0, (sum, e) => sum + e.amount),
  );
});

/// Configured expense categories from AppSettings
final expenseCategoriesProvider = Provider<List<String>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.expense.allCategories;
});
