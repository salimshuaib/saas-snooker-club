import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
// import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
// import 'package:snooker_club/features/expenses/data/expense_repository.dart';
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:snooker_club/features/expenses/presentation/widgets/expense_card.dart';
import 'package:snooker_club/features/expenses/presentation/widgets/settle_credit_dialog.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
// game models unused

class BusinessCreditScreen extends ConsumerStatefulWidget {
  const BusinessCreditScreen({super.key});

  @override
  ConsumerState<BusinessCreditScreen> createState() => _BusinessCreditScreenState();
}

class _BusinessCreditScreenState extends ConsumerState<BusinessCreditScreen> {
  int _selectedTabIndex = 0; // 0: Pending, 1: Settled, 2: All



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final creditExpensesAsync = ref.watch(businessCreditExpensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Credit Tracker'),
      ),
      body: creditExpensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (expenses) {
          final pending = expenses.where((e) => e.isOutstandingCredit).toList();
          final settled = expenses.where((e) => !e.isOutstandingCredit).toList();

          final totalPending = pending.fold<double>(0.0, (s, e) => s + e.amount);
          final totalSettled = settled.fold<double>(0.0, (s, e) => s + e.amount);

          List<Expense> displayed;
          if (_selectedTabIndex == 0) {
            displayed = pending;
          } else if (_selectedTabIndex == 1) {
            displayed = settled;
          } else {
            displayed = expenses;
          }

          return Column(
            children: [
              // Summary banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(6),
                              Text(
                                'Pending Payables',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            CurrencyHelper.format(totalPending, currency),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            '${pending.length} unpaid expense${pending.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(6),
                              Text(
                                'Settled History',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            CurrencyHelper.format(totalSettled, currency),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            '${settled.length} settled',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('Pending (${pending.length})'),
                      icon: const Icon(Icons.pending_actions, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Settled (${settled.length})'),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('All (${expenses.length})'),
                    ),
                  ],
                  selected: {_selectedTabIndex},
                  onSelectionChanged: (set) {
                    setState(() => _selectedTabIndex = set.first);
                  },
                ),
              ),
              const Gap(12),

              // List of expenses
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedTabIndex == 0
                                  ? Icons.thumb_up_alt_outlined
                                  : Icons.receipt_long_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const Gap(12),
                            Text(
                              _selectedTabIndex == 0
                                  ? 'No pending business credit!'
                                  : 'No credit transactions found.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayed.length,
                        itemBuilder: (context, index) {
                          final exp = displayed[index];
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
          );
        },
      ),
    );
  }
}
