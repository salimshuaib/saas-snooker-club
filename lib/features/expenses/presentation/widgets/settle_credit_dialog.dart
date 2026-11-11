import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

/// Shows an interactive settlement dialog to pay off an outstanding credit expense
Future<void> showSettleCreditDialog(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
) async {
  PaymentMethod settledMethod = PaymentMethod.cash;
  final currency = ref.read(currencyProvider);

  final selectedMethod = await showDialog<PaymentMethod>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final isCash = settledMethod == PaymentMethod.cash;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.handshake_rounded, color: AppColors.warning),
                Gap(10),
                Text('Settle Business Credit'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Gap(4),
                Text(
                  'Amount Due: ${CurrencyHelper.format(expense.amount, currency)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (expense.description != null && expense.description!.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    expense.description!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Gap(18),
                const Text(
                  'How was this bill paid?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => settledMethod = PaymentMethod.cash),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCash
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCash ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
                              width: isCash ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.money,
                                color: isCash
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const Gap(4),
                              Text(
                                'Cash',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCash
                                      ? AppColors.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => settledMethod = PaymentMethod.upi),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !isCash
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isCash ? AppColors.secondary : Theme.of(context).colorScheme.outlineVariant,
                              width: !isCash ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                color: !isCash
                                    ? AppColors.secondary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const Gap(4),
                              Text(
                                'UPI / Online',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isCash
                                      ? AppColors.secondary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCash
                        ? '💵 Deducted from today\'s cash register collections.'
                        : '📱 Recorded as an online bank / UPI settlement.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => Navigator.pop(ctx, settledMethod),
                child: const Text('Confirm Settle'),
              ),
            ],
          );
        },
      );
    },
  );

  if (selectedMethod != null && context.mounted) {
    try {
      await ref.read(expenseRepositoryProvider).markCreditAsPaid(
            expense.id,
            settledVia: selectedMethod,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Marked "${expense.title}" as settled via ${selectedMethod.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to settle credit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
