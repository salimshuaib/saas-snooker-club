import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

import 'package:snooker_club/core/models/currency.dart';

class BusinessInsightsCard extends StatelessWidget {
  final BusinessInsightsData data;
  final Currency currency;

  const BusinessInsightsCard({super.key, required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Business Insights', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(Icons.access_time, 'Peak Business Hour', data.busiestHour),
          _buildInsightRow(Icons.hourglass_empty, 'Slowest Business Hour', data.slowestHour),
          _buildInsightRow(Icons.calendar_today, 'Busiest Day', data.busiestDay),
          _buildInsightRow(Icons.table_restaurant, 'Best Table', data.bestPerformingTable),
          _buildInsightRow(Icons.pie_chart, 'Overall Utilization', '${data.tableUtilizationRate.toStringAsFixed(1)}%'),
          _buildInsightRow(Icons.people, 'Customers (New / Repeat)', '${data.newCustomersThisPeriod} / ${data.repeatCustomersThisPeriod}'),
          _buildInsightRow(Icons.attach_money, 'Avg Customer Spend', CurrencyHelper.formatWhole(data.averageCustomerSpend, currency)),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
