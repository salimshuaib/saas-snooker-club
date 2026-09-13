import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';

class AnalyticsDonutChart extends StatelessWidget {
  final String title;
  final List<CategoryShare> shares;

  const AnalyticsDonutChart({
    super.key,
    required this.title,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          title,
          style: AppTypography.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: shares
                  .map(
                    (s) => PieChartSectionData(
                      color: s.color,
                      value: s.amount,
                      title: '${s.percentage.toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: shares.map((s) => _buildLegendItem(s)).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(CategoryShare share) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: share.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          share.categoryName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
