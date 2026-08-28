import sys
import os

code = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_spacing.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_time_filter_bar.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/core/providers/app_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(completeAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AnalyticsTimeFilterBar(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialOverview(asyncData.revenueOverview, asyncData.periodComparison),
                  const SizedBox(height: AppSpacing.xl),
                  _buildTrendChart(asyncData.revenueTrendSeries, 'Revenue Trend (Billed)'),
                  const SizedBox(height: AppSpacing.xl),
                  _buildGamePerformance(asyncData.gameAnalytics),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickSalePerformance(asyncData.bestSellingProducts, asyncData.quickSaleCategories),
                  const SizedBox(height: AppSpacing.xl),
                  _buildBreakdowns(asyncData.paymentMethodsShare, asyncData.revenueSourceShare),
                  const SizedBox(height: AppSpacing.xl),
                  _buildCreditAnalytics(asyncData.creditAnalytics, asyncData.creditCollectionTrend),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFinancialOverview(RevenueOverviewData data, PeriodComparisonData? comparison) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial Overview', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Total Billed', data.totalBilled, Icons.account_balance_wallet, AppColors.primary, comparison?.totalBilledChange),
            _buildStatCard('Cash Collected', data.cashCollected, Icons.money, AppColors.success, comparison?.cashCollectedChange),
            _buildStatCard('UPI Collected', data.upiCollected, Icons.qr_code, AppColors.success, comparison?.upiCollectedChange),
            _buildStatCard('Credit Created', data.creditCreated, Icons.credit_score, AppColors.warning, comparison?.creditCreatedChange),
            _buildStatCard('Credit Collected', data.creditCollected, Icons.price_check, AppColors.success, comparison?.creditCollectedChange),
            _buildStatCard('Outstanding Credit', data.outstandingCredit, Icons.warning_amber, AppColors.error, null),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, double value, IconData icon, Color color, double? change) {
    final currency = ref.watch(currencyProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(CurrencyHelper.formatWhole(value, currency), style: AppTypography.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: color)),
          if (change != null) ...[
            const SizedBox(height: 4),
            Text(
              change == 0 ? 'No change' : '\\% vs prev',
              style: AppTypography.textTheme.bodySmall!.copyWith(color: change > 0 ? AppColors.success : (change < 0 ? AppColors.error : Colors.grey)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<TimeSeriesPoint> series, String title) {
    if (series.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      if (v.toInt() >= 0 && v.toInt() < series.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(series[v.toInt()].label, style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              barGroups: series.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamePerformance(GameAnalyticsData data) {
    final currency = ref.watch(currencyProvider);
    if (data.categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Game Performance', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...data.categories.map((c) => ListTile(
          title: Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('\ games | Avg \'),
          trailing: Text(CurrencyHelper.formatWhole(c.totalBilled, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildQuickSalePerformance(List<BestSellingProductItem> products, List<QuickSaleCategoryData> categories) {
    final currency = ref.watch(currencyProvider);
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Sale Performance (Top Products)', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...products.take(5).map((p) => ListTile(
          title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('\ units sold'),
          trailing: Text(CurrencyHelper.formatWhole(p.salesAmount, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 16)),
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildBreakdowns(List<CategoryShare> payments, List<CategoryShare> sources) {
    return Row(
      children: [
        Expanded(child: _buildDonut('Payment Distribution', payments)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildDonut('Revenue Sources', sources)),
      ],
    );
  }

  Widget _buildDonut(String title, List<CategoryShare> shares) {
    if (shares.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: shares.map((s) => PieChartSectionData(
                color: s.color,
                value: s.amount,
                title: '\%',
                radius: 40,
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditAnalytics(CreditAnalyticsData data, List<TimeSeriesPoint> creditTrend) {
    final currency = ref.watch(currencyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credit Analytics', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Credit Collections (This Period)'),
                    Text(CurrencyHelper.formatWhole(data.creditCollected, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Credit Created (This Period)'),
                    Text(CurrencyHelper.formatWhole(data.creditCreated, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Current Outstanding'),
                    Text(CurrencyHelper.formatWhole(data.currentOutstanding, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}'''

with open('lib/features/analytics/presentation/screens/analytics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code.replace('\\$', '$'))

with open('lib/features/analytics/presentation/widgets/analytics_time_filter_bar.dart', 'r', encoding='utf-8') as f:
    filter_code = f.read()
filter_code = filter_code.replace('setDateRange', 'setCustomRange')
with open('lib/features/analytics/presentation/widgets/analytics_time_filter_bar.dart', 'w', encoding='utf-8') as f:
    f.write(filter_code)
