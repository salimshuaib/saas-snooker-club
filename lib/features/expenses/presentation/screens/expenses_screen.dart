import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
// import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
// import 'package:snooker_club/features/expenses/data/expense_repository.dart';
// import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:snooker_club/features/expenses/presentation/screens/business_credit_screen.dart';
import 'package:snooker_club/features/expenses/presentation/widgets/expense_card.dart';
import 'package:snooker_club/features/expenses/presentation/widgets/settle_credit_dialog.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedCategoryFilter;
  PaymentMethod? _selectedMethodFilter;

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('equipment') || cat.contains('cue') || cat.contains('ball')) {
      return Icons.sports;
    } else if (cat.contains('maintenance') || cat.contains('plumber') || cat.contains('repair')) {
      return Icons.build_rounded;
    } else if (cat.contains('electric') || cat.contains('power')) {
      return Icons.bolt_rounded;
    } else if (cat.contains('water')) {
      return Icons.water_drop_rounded;
    } else if (cat.contains('rent')) {
      return Icons.home_work_rounded;
    } else if (cat.contains('salary') || cat.contains('wage') || cat.contains('staff')) {
      return Icons.people_rounded;
    } else if (cat.contains('inventory') || cat.contains('stock') || cat.contains('purchase')) {
      return Icons.inventory_2_rounded;
    } else if (cat.contains('petty')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.more_horiz_rounded;
  }

  IconData _getPaymentMethodIcon(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.upi:
        return Icons.qr_code_2;
      case PaymentMethod.credit:
        return Icons.credit_card;
      case null:
        return Icons.payments_outlined;
    }
  }

  String _getPaymentMethodLabel(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.credit:
        return 'Credit';
      case null:
        return 'All Payments';
    }
  }

  Future<void> _pickDateRange(
      BuildContext context, ExpenseDateRange currentRange) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: currentRange.start,
        end: currentRange.end.isAfter(currentRange.start)
            ? currentRange.end
            : currentRange.start,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(expenseDateRangeProvider.notifier).setCustomRange(
            picked.start,
            picked.end,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final dateRange = ref.watch(expenseDateRangeProvider);
    final expensesAsync = ref.watch(expensesForSelectedDateProvider);
    final unsettledCreditCount = ref.watch(unsettledBusinessCreditCountProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];
    final selectedFloorId = ref.watch(selectedFloorIdProvider);
    final selectedFloorMatch = floors.where((f) => f.id == selectedFloorId);
    final selectedFloor = selectedFloorMatch.isNotEmpty ? selectedFloorMatch.first : null;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final String dateDisplayTitle;
    if (dateRange.isSingleDay) {
      if (dateRange.start.year == todayStart.year &&
          dateRange.start.month == todayStart.month &&
          dateRange.start.day == todayStart.day) {
        dateDisplayTitle = 'Today, ${DateFormat('d MMM').format(dateRange.start)}';
      } else if (dateRange.start.year == yesterdayStart.year &&
          dateRange.start.month == yesterdayStart.month &&
          dateRange.start.day == yesterdayStart.day) {
        dateDisplayTitle = 'Yesterday, ${DateFormat('d MMM').format(dateRange.start)}';
      } else if (dateRange.start.year == now.year) {
        dateDisplayTitle = DateFormat('EEE, d MMM').format(dateRange.start);
      } else {
        dateDisplayTitle = DateFormat('EEE, d MMM yyyy').format(dateRange.start);
      }
    } else {
      if (dateRange.filter == ExpenseDateFilter.thisMonth &&
          dateRange.start.month == now.month &&
          dateRange.start.year == now.year) {
        dateDisplayTitle = '${DateFormat('MMMM yyyy').format(dateRange.start)} (This Month)';
      } else {
        final startFmt = dateRange.start.year == dateRange.end.year
            ? DateFormat('d MMM').format(dateRange.start)
            : DateFormat('d MMM yyyy').format(dateRange.start);
        final endFmt = DateFormat('d MMM yyyy').format(dateRange.end);
        final suffix = dateRange.filter != ExpenseDateFilter.custom
            ? ' • ${dateRange.filter.label}'
            : '';
        dateDisplayTitle = '$startFmt - $endFmt$suffix';
      }
    }

    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final canGoForward = dateRange.end.isBefore(todayEnd);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Expenses'),
        actions: [
          // Business Credit Tracker button with badge
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: unsettledCreditCount > 0 ? AppColors.warning : null,
            ),
            icon: Badge(
              isLabelVisible: unsettledCreditCount > 0,
              label: Text('$unsettledCreditCount'),
              backgroundColor: AppColors.warning,
              child: const Icon(Icons.credit_card_outlined),
            ),
            label: const Text('Credit Tracker'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessCreditScreen()),
              );
            },
          ),
          const Gap(4),
        ],
      ),
      body: Column(
        children: [
          // Date Navigation Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Period',
                  onPressed: () =>
                      ref.read(expenseDateRangeProvider.notifier).shiftRange(-1),
                ),
                Expanded(
                  child: Center(
                    child: InkWell(
                      onTap: () => _pickDateRange(context, dateRange),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const Gap(8),
                            Flexible(
                              child: Text(
                                dateDisplayTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(4),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Period',
                  onPressed: canGoForward
                      ? () =>
                          ref.read(expenseDateRangeProvider.notifier).shiftRange(1)
                      : null,
                ),
              ],
            ),
          ),

          // Date Presets Filter Chips Bar (Today, Yesterday, Last 7 Days, This Month, Last 6 Months, 1 Year, Custom)
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: ExpenseDateFilter.values.map((preset) {
                  final isSelected = dateRange.filter == preset;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () async {
                        if (preset == ExpenseDateFilter.custom) {
                          await _pickDateRange(context, dateRange);
                        } else {
                          ref
                              .read(expenseDateRangeProvider.notifier)
                              .setFilter(preset);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (preset == ExpenseDateFilter.custom) ...[
                              Icon(
                                Icons.tune_rounded,
                                size: 12,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const Gap(5),
                            ],
                            Text(
                              preset.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Floor Selector (if club has multiple floors)
          if (hasFloors && floors.length > 1)
            _buildFloorSelector(context, ref, theme, floors, selectedFloorId),

          // Daily summary card & filters
          expensesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error loading expenses: $err'),
            ),
            data: (expenses) {
              // Floor-scoped expenses: if a specific floor is selected, filter by that floor
              final floorScopedExpenses = selectedFloorId == null
                  ? expenses
                  : expenses.where((e) => e.floorId == selectedFloorId).toList();

              final totalExpense = floorScopedExpenses.fold<double>(0.0, (s, e) => s + e.amount);
              final cashExpenses = floorScopedExpenses
                  .where((e) =>
                      e.paymentMethod == PaymentMethod.cash ||
                      (e.isCredit && e.isSettled && e.settledPaymentMethod == PaymentMethod.cash))
                  .fold<double>(0.0, (s, e) => s + e.amount);
              final upiExpenses = floorScopedExpenses
                  .where((e) =>
                      e.paymentMethod == PaymentMethod.upi ||
                      (e.isCredit && e.isSettled && e.settledPaymentMethod == PaymentMethod.upi))
                  .fold<double>(0.0, (s, e) => s + e.amount);
              final creditExpenses = floorScopedExpenses
                  .where((e) => e.isOutstandingCredit)
                  .fold<double>(0.0, (s, e) => s + e.amount);

              // Filter expenses by category and payment method on top of floor scope
              var filtered = floorScopedExpenses;
              if (_selectedCategoryFilter != null) {
                filtered = filtered.where((e) => e.category == _selectedCategoryFilter).toList();
              }
              if (_selectedMethodFilter != null) {
                filtered = filtered.where((e) => e.paymentMethod == _selectedMethodFilter).toList();
              }

              return Expanded(
                child: Column(
                  children: [
                    // Daily Metrics Header
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateRange.isSingleDay
                                          ? 'Total Day Expenses'
                                          : (dateRange.filter != ExpenseDateFilter.custom
                                              ? 'Total Expenses (${dateRange.filter.label})'
                                              : 'Total Expenses (Custom Range)'),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Gap(4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        CurrencyHelper.format(totalExpense, currency),
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: totalExpense > 0
                                              ? AppColors.error
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.money_off, size: 16, color: AppColors.error),
                                    const Gap(6),
                                    Text(
                                      '${floorScopedExpenses.length} Item${floorScopedExpenses.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          const Divider(height: 1),
                          const Gap(12),
                          // Payment Breakdown Sub-row
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  label: '💵 Cash Paid',
                                  value: CurrencyHelper.format(cashExpenses, currency),
                                  color: AppColors.primary,
                                  tooltip: 'Deducted from register cash',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                              Expanded(
                                child: _buildMiniStat(
                                  label: '📱 UPI Paid',
                                  value: CurrencyHelper.format(upiExpenses, currency),
                                  color: AppColors.secondary,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                              Expanded(
                                child: _buildMiniStat(
                                  label: '💳 On Credit',
                                  value: CurrencyHelper.format(creditExpenses, currency),
                                  color: AppColors.warning,
                                  tooltip: 'Vendor credit to be paid later',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Category & Payment Filter Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          // Single-line dual filter row: [ All Expenses ⌄ ] [ All Payments ⌄ ]
                          Row(
                            children: [
                              // 1. Expense Type Dropdown
                              Expanded(
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedCategoryFilter != null
                                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      width: _selectedCategoryFilter != null ? 1.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedCategoryFilter != null
                                            ? _getCategoryIcon(_selectedCategoryFilter!)
                                            : Icons.category_outlined,
                                        size: 18,
                                        color: _selectedCategoryFilter != null
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const Gap(6),
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String?>(
                                            value: (categories.contains(_selectedCategoryFilter) || _selectedCategoryFilter == null)
                                                ? _selectedCategoryFilter
                                                : null,
                                            isExpanded: true,
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: _selectedCategoryFilter != null
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            dropdownColor: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(12),
                                            selectedItemBuilder: (context) {
                                              return [
                                                Row(
                                                  children: [
                                                    const Expanded(
                                                      child: Text(
                                                        'All Expenses',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const Gap(4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '${floorScopedExpenses.length}',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                ...categories.map((cat) {
                                                  final count = floorScopedExpenses.where((e) => e.category == cat).length;
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          cat,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: theme.colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                      if (count > 0) ...[
                                                        const Gap(4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            '$count',
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.bold,
                                                              color: theme.colorScheme.primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  );
                                                }),
                                              ];
                                            },
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.all_inclusive,
                                                      size: 18,
                                                      color: _selectedCategoryFilter == null
                                                          ? theme.colorScheme.primary
                                                          : theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                    const Gap(10),
                                                    const Text(
                                                      'All Expenses',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '${floorScopedExpenses.length}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...categories.map((cat) {
                                                final count = floorScopedExpenses.where((e) => e.category == cat).length;
                                                return DropdownMenuItem<String?>(
                                                  value: cat,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        _getCategoryIcon(cat),
                                                        size: 18,
                                                        color: _selectedCategoryFilter == cat
                                                            ? theme.colorScheme.primary
                                                            : theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                      const Gap(10),
                                                      Expanded(
                                                        child: Text(
                                                          cat,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: _selectedCategoryFilter == cat
                                                                ? FontWeight.bold
                                                                : FontWeight.w500,
                                                            color: _selectedCategoryFilter == cat
                                                                ? theme.colorScheme.primary
                                                                : theme.colorScheme.onSurface,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      if (count > 0) ...[
                                                        const Gap(6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            '$count',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: theme.colorScheme.primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: (val) {
                                              setState(() => _selectedCategoryFilter = val);
                                            },
                                          ),
                                        ),
                                      ),
                                      if (_selectedCategoryFilter != null) ...[
                                        const Gap(2),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          splashRadius: 14,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Clear type filter',
                                          onPressed: () {
                                            setState(() => _selectedCategoryFilter = null);
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const Gap(8),

                              // 2. Payment Type Dropdown
                              Expanded(
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedMethodFilter != null
                                          ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      width: _selectedMethodFilter != null ? 1.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getPaymentMethodIcon(_selectedMethodFilter),
                                        size: 18,
                                        color: _selectedMethodFilter != null
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const Gap(6),
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<PaymentMethod?>(
                                            value: _selectedMethodFilter,
                                            isExpanded: true,
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: _selectedMethodFilter != null
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            dropdownColor: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(12),
                                            selectedItemBuilder: (context) {
                                              return [
                                                Row(
                                                  children: [
                                                    const Expanded(
                                                      child: Text(
                                                        'All Payments',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    const Gap(4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '${floorScopedExpenses.length}',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                ...[
                                                  (PaymentMethod.cash, 'Cash'),
                                                  (PaymentMethod.upi, 'UPI'),
                                                  (PaymentMethod.credit, 'Credit'),
                                                ].map((item) {
                                                  final method = item.$1;
                                                  final name = item.$2;
                                                  final count = floorScopedExpenses.where((e) => e.paymentMethod == method).length;
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: theme.colorScheme.primary,
                                                          ),
                                                        ),
                                                      ),
                                                      if (count > 0) ...[
                                                        const Gap(4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            '$count',
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.bold,
                                                              color: theme.colorScheme.primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  );
                                                }),
                                              ];
                                            },
                                            items: [
                                              DropdownMenuItem<PaymentMethod?>(
                                                value: null,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.payments_outlined,
                                                      size: 18,
                                                      color: _selectedMethodFilter == null
                                                          ? theme.colorScheme.primary
                                                          : theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                    const Gap(10),
                                                    const Text(
                                                      'All Payments',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '${floorScopedExpenses.length}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...[
                                                (PaymentMethod.cash, 'Cash', Icons.money),
                                                (PaymentMethod.upi, 'UPI', Icons.qr_code_2),
                                                (PaymentMethod.credit, 'Credit', Icons.credit_card),
                                              ].map((item) {
                                                final method = item.$1;
                                                final name = item.$2;
                                                final icon = item.$3;
                                                final count = floorScopedExpenses.where((e) => e.paymentMethod == method).length;
                                                return DropdownMenuItem<PaymentMethod?>(
                                                  value: method,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        icon,
                                                        size: 18,
                                                        color: _selectedMethodFilter == method
                                                            ? theme.colorScheme.primary
                                                            : theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                      const Gap(10),
                                                      Text(
                                                        name,
                                                        style: TextStyle(
                                                          fontWeight: _selectedMethodFilter == method
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: _selectedMethodFilter == method
                                                              ? theme.colorScheme.primary
                                                              : theme.colorScheme.onSurface,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      if (count > 0) ...[
                                                        const Spacer(),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            '$count',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: theme.colorScheme.primary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: (val) {
                                              setState(() => _selectedMethodFilter = val);
                                            },
                                          ),
                                        ),
                                      ),
                                      if (_selectedMethodFilter != null) ...[
                                        const Gap(2),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          splashRadius: 14,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Clear payment filter',
                                          onPressed: () {
                                            setState(() => _selectedMethodFilter = null);
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (selectedFloorId != null || _selectedCategoryFilter != null || _selectedMethodFilter != null) ...[
                            const Gap(6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Filtering by: ${[
                                      if (selectedFloor != null) selectedFloor.name,
                                      ?_selectedCategoryFilter,
                                      if (_selectedMethodFilter != null) _getPaymentMethodLabel(_selectedMethodFilter!),
                                    ].join(' • ')}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                InkWell(
                                  onTap: () {
                                    ref.read(selectedFloorIdProvider.notifier).selectFloor(null);
                                    setState(() {
                                      _selectedCategoryFilter = null;
                                      _selectedMethodFilter = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.filter_alt_off, size: 14, color: theme.colorScheme.error),
                                        const Gap(4),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(6),

                    // Expenses List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                  ),
                                  const Gap(12),
                                  Text(
                                    expenses.isEmpty
                                        ? (dateRange.isSingleDay ? 'No expenses recorded for this date.' : 'No expenses recorded for this period.')
                                        : 'No expenses match the selected filter.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const Gap(8),
                                  if (expenses.isEmpty)
                                    Text(
                                      'Tap "+ Record Expense" below to add plumber, supplies, or bills.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.filter_alt_off, size: 16),
                                        label: const Text('Clear Filters'),
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategoryFilter = null;
                                            _selectedMethodFilter = null;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final exp = filtered[index];
                                return ExpenseCard(
                                  expense: exp,
                                  onEdit: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddExpenseScreen(expenseToEdit: exp),
                                      ),
                                    );
                                  },
                                  onMarkPaid: exp.isOutstandingCredit
                                      ? () => showSettleCreditDialog(context, ref, exp)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Record Expense'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),
    );
  }

  Widget _buildFloorSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<FloorModel> floors,
    String? selectedFloorId,
  ) {
    final sortedFloors = List<FloorModel>.from(floors);
    sortedFloors.sort((a, b) {
      int getRank(FloorModel f) {
        final n = f.name.toLowerCase();
        if (n.contains('first') || n.contains('floor 1') || n.contains('1st') || n == '1') return 1;
        if (n.contains('second') || n.contains('floor 2') || n.contains('2nd') || n == '2') return 2;
        if (n.contains('third') || n.contains('floor 3') || n.contains('3rd') || n == '3') return 3;
        if (n.contains('fourth') || n.contains('floor 4') || n.contains('4th') || n == '4') return 4;
        return 10 + f.order;
      }
      final rankA = getRank(a);
      final rankB = getRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.name.compareTo(b.name);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedFloorId != null
                ? theme.colorScheme.primary.withValues(alpha: 0.7)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selectedFloorId != null ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 18,
              color: selectedFloorId != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(8),
            Text(
              'Floor:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: (sortedFloors.any((f) => f.id == selectedFloorId) || selectedFloorId == null)
                      ? selectedFloorId
                      : sortedFloors.first.id,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: selectedFloorId != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Floors',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                    ...sortedFloors.map(
                      (floor) => DropdownMenuItem<String?>(
                        value: floor.id,
                        child: Text(
                          floor.name,
                          style: TextStyle(
                            fontWeight: selectedFloorId == floor.id
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: selectedFloorId == floor.id
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (newFloorId) {
                    ref.read(selectedFloorIdProvider.notifier).selectFloor(newFloorId);
                  },
                ),
              ),
            ),
            if (selectedFloorId != null) ...[
              const Gap(4),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear floor filter',
                onPressed: () {
                  ref.read(selectedFloorIdProvider.notifier).selectFloor(null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    String? tooltip,
  }) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Gap(2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: content);
    }
    return content;
  }
}
