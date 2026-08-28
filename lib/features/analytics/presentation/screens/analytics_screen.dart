import 'package:flutter/material.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_spacing.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_time_filter_bar.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_stat_card.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_bar_chart.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_donut_chart.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/business_insights_card.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/table_performance_card.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/table_ranking_list.dart';
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
    final asyncData = getCompleteAnalyticsData(ref);
    final currency = ref.watch(currencyProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics & Insights'),
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Tables', icon: Icon(Icons.table_restaurant)),
              Tab(text: 'Sales & Inv.', icon: Icon(Icons.shopping_cart)),
              Tab(text: 'Credit', icon: Icon(Icons.credit_score)),
            ],
          ),
        ),
        body: Column(
          children: [
            const AnalyticsTimeFilterBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(asyncData, currency),
                  _buildTablesTab(asyncData, currency),
                  _buildSalesTab(asyncData, currency),
                  _buildCreditTab(asyncData, currency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── OVERVIEW TAB ───
  Widget _buildOverviewTab(CompleteAnalyticsData data, Currency currency) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildFinancialOverview(data.revenueOverview, data.periodComparison, currency),
        const SizedBox(height: AppSpacing.xl),
        AnalyticsBarChart(series: data.revenueTrendSeries, title: 'Revenue Trend (Billed)'),
        const SizedBox(height: AppSpacing.xl),
        BusinessInsightsCard(data: data.businessInsights, currency: currency),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: AnalyticsDonutChart(title: 'Payment Distribution', shares: data.paymentMethodsShare)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: AnalyticsDonutChart(title: 'Revenue Sources', shares: data.revenueSourceShare)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildFinancialOverview(RevenueOverviewData data, PeriodComparisonData? comparison, Currency currency) {
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
            AnalyticsStatCard(title: 'Total Billed', value: data.totalBilled, icon: Icons.account_balance_wallet, color: AppColors.primary, percentageChange: comparison?.totalBilledChange, currency: currency),
            AnalyticsStatCard(title: 'Cash Collected', value: data.cashCollected, icon: Icons.money, color: AppColors.success, percentageChange: comparison?.cashCollectedChange, currency: currency),
            AnalyticsStatCard(title: 'UPI Collected', value: data.upiCollected, icon: Icons.qr_code, color: AppColors.info, percentageChange: comparison?.upiCollectedChange, currency: currency),
            AnalyticsStatCard(title: 'Credit Created', value: data.creditCreated, icon: Icons.credit_card, color: AppColors.warning, percentageChange: comparison?.creditCreatedChange, currency: currency),
            AnalyticsStatCard(title: 'Credit Collected', value: data.creditCollected, icon: Icons.price_check, color: AppColors.success, percentageChange: comparison?.creditCollectedChange, currency: currency),
            AnalyticsStatCard(title: 'Outstanding Credit', value: data.outstandingCredit, icon: Icons.warning_amber, color: AppColors.error, percentageChange: null, currency: currency),
          ],
        ),
      ],
    );
  }

  // ─── TABLES TAB ───
  Widget _buildTablesTab(CompleteAnalyticsData data, Currency currency) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TableRankingList(tables: data.tablePerformances, currency: currency),
        const SizedBox(height: AppSpacing.xl),
        AnalyticsBarChart(series: data.peakBusinessHours, title: 'Peak Hours (Sessions Started)', barColor: AppColors.secondary),
        const SizedBox(height: AppSpacing.xl),
        Text('Table Performance Profiles', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...data.tablePerformances.map((t) => TablePerformanceCard(data: t, currency: currency)),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ─── SALES TAB ───
  Widget _buildSalesTab(CompleteAnalyticsData data, Currency currency) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(child: AnalyticsStatCard(title: 'Total Sales Revenue', value: data.revenueOverview.totalQuickSaleBilled, icon: Icons.shopping_bag, color: AppColors.tertiary, currency: currency)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: AnalyticsStatCard(title: 'Inventory Value', value: data.inventoryAnalytics.totalInventoryValue, icon: Icons.inventory_2, color: AppColors.info, currency: currency)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: AnalyticsStatCard(title: 'Cost of Goods Sold', value: data.inventoryAnalytics.costOfGoodsSold, icon: Icons.trending_down, color: AppColors.warning, currency: currency)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: AnalyticsStatCard(title: 'Gross Profit (Est)', value: data.inventoryAnalytics.grossProfit, icon: Icons.trending_up, color: AppColors.success, currency: currency)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (data.bestSellingProducts.isNotEmpty) ...[
          Text('Top Selling Products', style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          ...data.bestSellingProducts.take(5).map((p) => ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.tertiary, child: Icon(Icons.fastfood, color: Colors.white, size: 16)),
            title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p.unitsSold} units sold'),
            trailing: Text(CurrencyHelper.formatWhole(p.salesAmount, currency), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 16)),
            contentPadding: EdgeInsets.zero,
          )),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ─── CREDIT TAB ───
  Widget _buildCreditTab(CompleteAnalyticsData data, Currency currency) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AnalyticsStatCard(title: 'Credit Created', value: data.creditAnalytics.creditCreated, icon: Icons.credit_card, color: AppColors.warning, currency: currency),
            AnalyticsStatCard(title: 'Credit Collected', value: data.creditAnalytics.creditCollected, icon: Icons.price_check, color: AppColors.success, currency: currency),
            AnalyticsStatCard(title: 'Outstanding Balance', value: data.creditAnalytics.currentOutstanding, icon: Icons.warning_amber, color: AppColors.error, currency: currency),
            AnalyticsStatCard(title: 'Pending Customers', value: data.creditAnalytics.pendingCustomersCount.toDouble(), icon: Icons.people_outline, color: AppColors.info, isCurrency: false, currency: currency),
            AnalyticsStatCard(title: 'Avg Collection Amount', value: data.creditAnalytics.averageCreditAmount, icon: Icons.analytics, color: AppColors.primary, currency: currency),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AnalyticsBarChart(series: data.creditCollectionTrend, title: 'Credit Collections Trend', barColor: AppColors.success),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}