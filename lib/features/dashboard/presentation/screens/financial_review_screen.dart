import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

class FinancialReviewScreen extends ConsumerWidget {
  const FinancialReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsData = ref.watch(completeAnalyticsProvider);
    final timeRange = ref.watch(analyticsTimeRangeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text("Financial Review"),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildDateNavigation(context, ref, timeRange, theme),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewCard(context, ref, analyticsData, theme),
                const Gap(16),
                _buildRevenueBreakdown(analyticsData, theme),
                const Gap(16),
                _buildPaymentCollection(analyticsData, theme),
                const Gap(16),
                _buildKeyMetrics(analyticsData, theme),
                const Gap(16),
                _buildGamePerformance(analyticsData, theme),
                const Gap(16),
                _buildTablePerformance(analyticsData, theme),
                const Gap(16),
                _buildFinancialSummary(analyticsData, theme),
                const Gap(32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation(BuildContext context, WidgetRef ref, AnalyticsTimeRange timeRange, ThemeData theme) {
    final filter = ref.watch(analyticsTimeFilterProvider);
    final formatter = DateFormat("MMM d, yyyy");
    final String dateStr;
    if (timeRange.start.day == timeRange.end.day && timeRange.start.month == timeRange.end.month && timeRange.start.year == timeRange.end.year) {
      final now = DateTime.now();
      if (timeRange.start.day == now.day && timeRange.start.month == now.month && timeRange.start.year == now.year) {
        dateStr = "Today, ${formatter.format(timeRange.start)}";
      } else {
        dateStr = formatter.format(timeRange.start);
      }
    } else {
      dateStr = "${formatter.format(timeRange.start)} - ${formatter.format(timeRange.end)}";
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: theme.colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(analyticsTimeFilterProvider.notifier).shiftDateRange(-1),
              ),
              Expanded(
                child: Text(
                  dateStr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final now = DateTime.now();
                  if (timeRange.end.isBefore(DateTime(now.year, now.month, now.day))) {
                    ref.read(analyticsTimeFilterProvider.notifier).shiftDateRange(1);
                  }
                },
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: AnalyticsTimeFilter.values.where((f) => f != AnalyticsTimeFilter.custom).map((f) {
              final isSelected = filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(_getFilterName(f)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(analyticsTimeFilterProvider.notifier).setFilter(f);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getFilterName(AnalyticsTimeFilter filter) {
    switch (filter) {
      case AnalyticsTimeFilter.today: return "Today";
      case AnalyticsTimeFilter.yesterday: return "Yesterday";
      case AnalyticsTimeFilter.currentWeek: return "This Week";
      case AnalyticsTimeFilter.last7Days: return "Last 7 Days";
      case AnalyticsTimeFilter.lastWeek: return "Last Week";
      case AnalyticsTimeFilter.currentMonth: return "This Month";
      case AnalyticsTimeFilter.lastMonth: return "Last Month";
      case AnalyticsTimeFilter.currentYear: return "This Year";
      case AnalyticsTimeFilter.custom: return "Custom";
    }
  }

  Widget _buildOverviewCard(BuildContext context, WidgetRef ref, CompleteAnalyticsData data, ThemeData theme) {
    final currency = ref.watch(currencyProvider);
    
    
    String changeText = "No previous data";
    Color changeColor = Colors.grey;

    if (data.periodComparison != null) {
      final change = data.periodComparison!.totalBilledChange;
      final diffAmt = data.revenueOverview.totalBilled - data.periodComparison!.previousPeriod.totalBilled;
      
      if (change > 0) {
        changeText = "↑ ${CurrencyHelper.format(diffAmt, currency)} more than previous";
        changeColor = AppColors.success;
      } else if (change < 0) {
        changeText = "↓ ${CurrencyHelper.format(diffAmt.abs(), currency)} less than previous";
        changeColor = AppColors.error;
      } else {
        changeText = "Same as previous period";
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Financial Overview", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
            const Gap(8),
            Text("Total Revenue", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7))),
            const Gap(4),
            Text(
              CurrencyHelper.format(data.revenueOverview.totalBilled, currency),
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                changeText,
                style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown(CompleteAnalyticsData data, ThemeData theme) {
    return _buildSectionCard(
      theme,
      title: "Revenue Breakdown",
      child: Column(
        children: [
          if (data.revenueOverview.totalGameBilled > 0)
            _buildTableRow("Game Revenue", data.revenueOverview.totalGameBilled, theme),
          if (data.revenueOverview.totalQuickSaleBilled > 0)
            _buildTableRow("Food & Drinks (Quick Sales)", data.revenueOverview.totalQuickSaleBilled, theme),
          if (data.revenueOverview.totalGameBilled == 0 && data.revenueOverview.totalQuickSaleBilled == 0)
            const Text("No revenue generated in this period.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaymentCollection(CompleteAnalyticsData data, ThemeData theme) {
    return _buildSectionCard(
      theme,
      title: "Payment Collection",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactMetric("💵 Cash", data.revenueOverview.cashCollected, theme),
          _buildCompactMetric("📱 UPI", data.revenueOverview.upiCollected, theme),
          _buildCompactMetric("💳 Credit Given", data.revenueOverview.creditCreated, theme, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(CompleteAnalyticsData data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Key Financial Metrics", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(child: _buildMetricCard("Total Transactions", "${data.gameAnalytics.totalGameSessions + data.quickSaleCategories.fold(0, (sum, cat) => sum + cat.transactionCount)}", theme)),
            const Gap(8),
            Expanded(child: _buildMetricCard("Completed Games", "${data.gameAnalytics.totalGameSessions}", theme)),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(child: _buildMetricCard("Credit Recovered", data.revenueOverview.creditCollected, theme, isMoney: true)),
            const Gap(8),
            Expanded(child: _buildMetricCard("Outstanding Credit", data.revenueOverview.outstandingCredit, theme, isMoney: true, color: AppColors.error)),
          ],
        ),
      ],
    );
  }

  Widget _buildGamePerformance(CompleteAnalyticsData data, ThemeData theme) {
    return _buildSectionCard(
      theme,
      title: "Game Performance",
      child: Column(
        children: [
          ...data.gameAnalytics.categories.where((c) => c.transactionCount > 0).map((c) => _buildTableRow(
            c.categoryName,
            c.totalBilled,
            theme,
            subtitle: "${c.transactionCount} Games",
          )),
          if (data.gameAnalytics.categories.every((c) => c.transactionCount == 0))
            const Text("No games played in this period.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTablePerformance(CompleteAnalyticsData data, ThemeData theme) {
    return _buildSectionCard(
      theme,
      title: "Table Performance",
      child: Column(
        children: [
          ...data.tablePerformances.where((t) => t.sessionsCount > 0).map((t) {
            final hours = t.totalDurationMinutes ~/ 60;
            final mins = t.totalDurationMinutes % 60;
            return _buildTableRow(
              t.tableName,
              t.totalBilled,
              theme,
              subtitle: "${hours}h ${mins}m • ${t.sessionsCount} Games",
            );
          }),
          if (data.tablePerformances.every((t) => t.sessionsCount == 0))
            const Text("No table usage in this period.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(CompleteAnalyticsData data, ThemeData theme) {
    return _buildSectionCard(
      theme,
      title: "Financial Summary",
      child: Column(
        children: [
          _buildTableRow("Total Revenue", data.revenueOverview.totalBilled, theme),
          _buildTableRow("Total Expenses", 0.0, theme), // Placeholder for expenses
          const Divider(),
          _buildTableRow("Net Earnings", data.revenueOverview.totalBilled, theme, isBold: true, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, {required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String title, double amount, ThemeData theme, {String? subtitle, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color)),
              if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Consumer(
            builder: (context, ref, _) {
              final currency = ref.watch(currencyProvider);
              return Text(
                CurrencyHelper.format(amount, currency),
                style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String label, double amount, ThemeData theme, {Color? color}) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
        const Gap(4),
        Consumer(
          builder: (context, ref, _) {
            final currency = ref.watch(currencyProvider);
            return Text(
              CurrencyHelper.format(amount, currency),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
            );
          }
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, dynamic value, ThemeData theme, {bool isMoney = false, Color? color}) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Gap(4),
            if (isMoney)
              Consumer(builder: (context, ref, _) {
                final currency = ref.watch(currencyProvider);
                return Text(CurrencyHelper.format(value, currency), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color));
              })
            else
              Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        ),
      ),
    );
  }
}
