import 'package:flutter/material.dart';

/// Time horizons supported by the Analytics dashboard.
enum AnalyticsTimeFilter {
  today,
  yesterday,
  last7Days,
  currentWeek,
  lastWeek,
  currentMonth,
  lastMonth,
  currentYear,
  custom,
}

extension AnalyticsTimeFilterX on AnalyticsTimeFilter {
  String get label {
    switch (this) {
      case AnalyticsTimeFilter.today:
        return 'Today';
      case AnalyticsTimeFilter.yesterday:
        return 'Yesterday';
      case AnalyticsTimeFilter.last7Days:
        return 'Last 7 Days';
      case AnalyticsTimeFilter.currentWeek:
        return 'Current Week';
      case AnalyticsTimeFilter.lastWeek:
        return 'Last Week';
      case AnalyticsTimeFilter.currentMonth:
        return 'Current Month';
      case AnalyticsTimeFilter.lastMonth:
        return 'Last Month';
      case AnalyticsTimeFilter.currentYear:
        return 'Current Year';
      case AnalyticsTimeFilter.custom:
        return 'Custom Date Range';
    }
  }
}

/// Active date boundaries corresponding to the chosen filter.
class AnalyticsTimeRange {
  final AnalyticsTimeFilter filter;
  final DateTime start;
  final DateTime end;

  const AnalyticsTimeRange({
    required this.filter,
    required this.start,
    required this.end,
  });
}

/// Section 1: Revenue Overview Summary Cards
class RevenueOverviewData {
  final double totalBilled;
  final double cashCollected;
  final double upiCollected;
  final double creditCreated;
  final double creditCollected;
  final double outstandingCredit;
  final double totalGameBilled;
  final double totalQuickSaleBilled;

  const RevenueOverviewData({
    required this.totalBilled,
    required this.cashCollected,
    required this.upiCollected,
    required this.creditCreated,
    required this.creditCollected,
    required this.outstandingCredit,
    required this.totalGameBilled,
    required this.totalQuickSaleBilled,
  });
}

/// A generic data point for charts (Line/Bar charts).
class TimeSeriesPoint {
  final String label;
  final double value;
  final int count;

  const TimeSeriesPoint({
    required this.label,
    required this.value,
    this.count = 0,
  });
}

/// For Pie/Donut charts
class CategoryShare {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryShare({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

/// Game Category Performance
class GameCategoryData {
  final String categoryName;
  final double totalBilled;
  final int transactionCount;
  final double averageTransactionValue;

  const GameCategoryData({
    required this.categoryName,
    required this.totalBilled,
    required this.transactionCount,
    required this.averageTransactionValue,
  });
}

class GameAnalyticsData {
  final List<GameCategoryData> categories;
  final int totalGameSessions;

  // Game Mode Analytics (if applicable)
  final double perMinuteBilled;
  final double perFrameBilled;

  // TP vs Friendly
  final double splitBilled;
  final double singlePayerBilled;
  final int splitCount;
  final int singlePayerCount;

  const GameAnalyticsData({
    required this.categories,
    required this.totalGameSessions,
    this.perMinuteBilled = 0.0,
    this.perFrameBilled = 0.0,
    this.splitBilled = 0.0,
    this.singlePayerBilled = 0.0,
    this.splitCount = 0,
    this.singlePayerCount = 0,
  });
}

/// Table Performance
class TablePerformanceItem {
  final String tableId;
  final String tableName;
  final String tableType; // NEW
  final int sessionsCount;
  final double totalBilled;
  final double averageSessionValue;
  final double totalOrdersRevenue; // NEW
  final int totalDurationMinutes; // NEW
  final int avgDurationMinutes; // NEW
  final double utilizationPercent; // NEW
  final Map<int, int> hourlyUsage; // NEW
  final Map<int, int> dailyUsage; // NEW
  final double revenuePerHour; // NEW
  final int overtimeCount; // NEW

  const TablePerformanceItem({
    required this.tableId,
    required this.tableName,
    required this.tableType,
    required this.sessionsCount,
    required this.totalBilled,
    required this.averageSessionValue,
    required this.totalOrdersRevenue,
    required this.totalDurationMinutes,
    required this.avgDurationMinutes,
    required this.utilizationPercent,
    required this.hourlyUsage,
    required this.dailyUsage,
    required this.revenuePerHour,
    required this.overtimeCount,
  });
}

/// Best Selling Products (Quick Sales)
class BestSellingProductItem {
  final String productId;
  final String productName;
  final int unitsSold;
  final double salesAmount;

  const BestSellingProductItem({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.salesAmount,
  });
}

/// Quick Sale Category Analytics
class QuickSaleCategoryData {
  final String categoryName;
  final double totalSales;
  final int unitsSold;
  final int transactionCount;
  final double averageSaleValue;

  const QuickSaleCategoryData({
    required this.categoryName,
    required this.totalSales,
    required this.unitsSold,
    required this.transactionCount,
    required this.averageSaleValue,
  });
}

/// Credit Analytics
class CreditAnalyticsData {
  final double creditCreated;
  final double creditCollected;
  final double currentOutstanding;
  final int numberOfCreditTransactions;
  final int pendingCustomersCount;
  final double averageCreditAmount;

  const CreditAnalyticsData({
    required this.creditCreated,
    required this.creditCollected,
    required this.currentOutstanding,
    required this.numberOfCreditTransactions,
    required this.pendingCustomersCount,
    required this.averageCreditAmount,
  });
}

/// Period Comparison
class PeriodComparisonData {
  final RevenueOverviewData currentPeriod;
  final RevenueOverviewData previousPeriod;

  const PeriodComparisonData({
    required this.currentPeriod,
    required this.previousPeriod,
  });

  double get totalBilledChange =>
      _calcChange(currentPeriod.totalBilled, previousPeriod.totalBilled);
  double get cashCollectedChange =>
      _calcChange(currentPeriod.cashCollected, previousPeriod.cashCollected);
  double get upiCollectedChange =>
      _calcChange(currentPeriod.upiCollected, previousPeriod.upiCollected);
  double get creditCreatedChange =>
      _calcChange(currentPeriod.creditCreated, previousPeriod.creditCreated);
  double get creditCollectedChange => _calcChange(
    currentPeriod.creditCollected,
    previousPeriod.creditCollected,
  );

  double _calcChange(double current, double previous) {
    if (previous == 0) return 0.0;
    return ((current - previous) / previous) * 100;
  }
}

/// Business Insights
class BusinessInsightsData {
  final int totalUniqueCustomers;
  final int newCustomersThisPeriod;
  final int repeatCustomersThisPeriod;
  final double averageCustomerSpend;
  final double averageSessionDuration;
  final double tableUtilizationRate;
  final String busiestHour;
  final String slowestHour;
  final String busiestDay;
  final String bestPerformingTable;
  final String worstPerformingTable;

  const BusinessInsightsData({
    required this.totalUniqueCustomers,
    required this.newCustomersThisPeriod,
    required this.repeatCustomersThisPeriod,
    required this.averageCustomerSpend,
    required this.averageSessionDuration,
    required this.tableUtilizationRate,
    required this.busiestHour,
    required this.slowestHour,
    required this.busiestDay,
    required this.bestPerformingTable,
    required this.worstPerformingTable,
  });
}

/// Inventory Analytics
class InventoryAnalyticsData {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;
  final double costOfGoodsSold;
  final double grossProfit;

  const InventoryAnalyticsData({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalInventoryValue,
    required this.costOfGoodsSold,
    required this.grossProfit,
  });
}

/// Complete Aggregation Object
class CompleteAnalyticsData {
  final AnalyticsTimeRange timeRange;
  final RevenueOverviewData revenueOverview;
  final List<TimeSeriesPoint> revenueTrendSeries;
  final List<CategoryShare> paymentMethodsShare;
  final List<CategoryShare> revenueSourceShare;

  final GameAnalyticsData gameAnalytics;
  final List<TablePerformanceItem> tablePerformances;

  final List<BestSellingProductItem> bestSellingProducts;
  final List<QuickSaleCategoryData> quickSaleCategories;

  final CreditAnalyticsData creditAnalytics;
  final List<TimeSeriesPoint> creditCollectionTrend;

  final List<TimeSeriesPoint> peakBusinessHours;
  final PeriodComparisonData? periodComparison;

  final BusinessInsightsData businessInsights;
  final InventoryAnalyticsData inventoryAnalytics;

  const CompleteAnalyticsData({
    required this.timeRange,
    required this.revenueOverview,
    required this.revenueTrendSeries,
    required this.paymentMethodsShare,
    required this.revenueSourceShare,
    required this.gameAnalytics,
    required this.tablePerformances,
    required this.bestSellingProducts,
    required this.quickSaleCategories,
    required this.creditAnalytics,
    required this.creditCollectionTrend,
    required this.peakBusinessHours,
    this.periodComparison,
    required this.businessInsights,
    required this.inventoryAnalytics,
  });
}
