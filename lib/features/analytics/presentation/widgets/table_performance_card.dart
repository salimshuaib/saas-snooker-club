import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

import 'package:snooker_club/core/models/currency.dart';

class TablePerformanceCard extends StatelessWidget {
  final TablePerformanceItem data;
  final Currency currency;

  const TablePerformanceCard({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.tableType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.tableName,
                          style: AppTypography.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyHelper.formatWhole(data.totalBilled, currency),
                  style: AppTypography.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Sessions', data.sessionsCount.toString()),
                _buildMetric(
                  'Avg Session',
                  CurrencyHelper.formatWhole(
                    data.averageSessionValue,
                    currency,
                  ),
                ),
                _buildMetric('Avg Duration', '${data.avgDurationMinutes}m'),
                _buildMetric(
                  'Rev/Hour',
                  CurrencyHelper.formatWhole(data.revenuePerHour, currency),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Utilization', style: AppTypography.textTheme.bodyMedium),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: data.utilizationPercent / 100,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        color: _getUtilizationColor(data.utilizationPercent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.utilizationPercent.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Color _getUtilizationColor(double percent) {
    if (percent < 20) return AppColors.error;
    if (percent < 50) return AppColors.warning;
    return AppColors.success;
  }
}
