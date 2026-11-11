import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
// expense repo not needed here
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/expenses/presentation/widgets/settle_credit_dialog.dart';

class ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkPaid;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onMarkPaid,
  });

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

  void _handleSettle(BuildContext context, WidgetRef ref) {
    if (onMarkPaid != null) {
      onMarkPaid!();
    } else {
      showSettleCreditDialog(context, ref, expense);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final dtFmt = DateFormat('d MMM, hh:mm a');

    // credit check
    final isUnsettledCredit = expense.isOutstandingCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnsettledCredit
              ? AppColors.warning.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isUnsettledCredit ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Category icon + Title + Amount + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isUnsettledCredit
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    size: 20,
                    color: isUnsettledCredit
                        ? AppColors.warning
                        : theme.colorScheme.primary,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            expense.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (expense.floorName != null && expense.floorName!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.layers_outlined, size: 11, color: theme.colorScheme.primary),
                                  const Gap(3),
                                  Text(
                                    expense.floorName!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 135),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyHelper.format(expense.amount, currency),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isUnsettledCredit
                                ? AppColors.warning
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const Gap(4),
                      // Payment method pill
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: _buildPaymentBadge(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (expense.description != null &&
                expense.description!.trim().isNotEmpty) ...[
              const Gap(10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  expense.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const Gap(12),
            const Divider(height: 1),
            const Gap(8),

            // Bottom row: Date, Staff, Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const Gap(4),
                      Text(
                        dtFmt.format(expense.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (expense.createdByName != null && expense.createdByName!.isNotEmpty) ...[
                        const Gap(6),
                        Text('•', style: TextStyle(color: theme.colorScheme.outline)),
                        const Gap(6),
                        Flexible(
                          child: Text(
                            expense.createdByName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnsettledCredit) ...[
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: AppColors.warning.withValues(alpha: 0.18),
                          foregroundColor: AppColors.warning,
                        ),
                        onPressed: () => _handleSettle(context, ref),
                        icon: const Icon(Icons.handshake_outlined, size: 16),
                        label: const Text('Settle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Gap(6),
                    ],
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      itemBuilder: (context) => [
                        if (isUnsettledCredit)
                          const PopupMenuItem(
                            value: 'pay',
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 18, color: AppColors.success),
                                Gap(8),
                                Text('Settle Credit'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              Gap(8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              Gap(8),
                              Text('Delete', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'pay') {
                          _handleSettle(context, ref);
                        } else if (val == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (val == 'delete') {
                          _confirmDelete(context, ref);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(BuildContext context) {
    if (expense.isCredit) {
      if (expense.isOutstandingCredit) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.credit_card, size: 12, color: AppColors.warning),
              Gap(4),
              Text(
                'Credit (Unpaid)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        );
      } else {
        final via = expense.settledPaymentMethod?.displayName ?? 'Paid';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 12, color: AppColors.success),
              const Gap(4),
              Text(
                'Credit Settled ($via)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      }
    }

    final isCash = expense.paymentMethod == PaymentMethod.cash;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCash
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCash ? Icons.money : Icons.qr_code_2,
            size: 12,
            color: isCash ? AppColors.primary : AppColors.secondary,
          ),
          const Gap(4),
          Text(
            expense.paymentMethod.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCash ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${expense.title}"? This will update financial calculations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(expenseRepositoryProvider).deleteExpense(expense.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted successfully')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
