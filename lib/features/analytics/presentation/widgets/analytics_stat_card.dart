import 'package:flutter/material.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final double? percentageChange;
  final bool isCurrency;
  final Currency currency;

  const AnalyticsStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.percentageChange,
    this.isCurrency = true,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isCurrency
        ? CurrencyHelper.formatWhole(value, currency)
        : value.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayValue,
            style: AppTypography.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (percentageChange != null) ...[
            const SizedBox(height: 4),
            Text(
              percentageChange == 0
                  ? 'No change'
                  : '${percentageChange! > 0 ? '+' : ''}${percentageChange!.toStringAsFixed(1)}% vs prev',
              style: AppTypography.textTheme.bodySmall!.copyWith(
                color: percentageChange! > 0
                    ? AppColors.success
                    : (percentageChange! < 0 ? AppColors.error : Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
