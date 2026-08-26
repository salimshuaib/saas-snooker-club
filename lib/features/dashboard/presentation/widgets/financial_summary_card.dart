import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/dashboard/providers/financial_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/models/currency.dart';

class FinancialSummaryCard extends ConsumerWidget {
  final bool forSelectedDate;
  final bool isInteractive;

  const FinancialSummaryCard({
    super.key,
    this.forSelectedDate = false,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final asyncSummary = ref.watch(financialSummaryProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isInteractive ? () {
          context.push('/financial-review');
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: asyncSummary.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (summary) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isInteractive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Financial Overview", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    )
                  else
                    Text("Financial Overview", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    
                  const Divider(height: 24),
                  
                  // Total Billed (Business Volume)
                  _buildRow("Total Billed", summary.totalBilled, currency, theme, isBold: true, color: AppColors.primary),
                  const Gap(8),

                  // Collections
                  Text("Collections", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                  const Gap(4),
                  _buildRow("Cash Collected", summary.cashCollected, currency, theme, color: AppColors.success),
                  _buildRow("UPI Collected", summary.upiCollected, currency, theme, color: AppColors.success),
                  _buildRow("Credit Collected", summary.creditCollected, currency, theme, color: AppColors.success),
                  
                  const Divider(height: 24),

                  // Credit
                  Text("Credit Activity", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                  const Gap(4),
                  _buildRow("Credit Created", summary.creditCreated, currency, theme, color: AppColors.warning),
                  if (!forSelectedDate)
                    _buildRow("Outstanding Credit", summary.outstandingCredit, currency, theme, color: AppColors.error),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, double amount, Currency currency, ThemeData theme, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            CurrencyHelper.formatWhole(amount, currency), 
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            )
          ),
        ],
      ),
    );
  }
}
