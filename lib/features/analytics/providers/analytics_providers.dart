import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/analytics/domain/models/analytics_models.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';

// â”€â”€â”€ State Notifiers â”€â”€â”€

class AnalyticsTimeFilterNotifier extends Notifier<AnalyticsTimeFilter> {
  @override
  AnalyticsTimeFilter build() => AnalyticsTimeFilter.today;
  
  void setFilter(AnalyticsTimeFilter filter) => state = filter;

  void shiftDateRange(int offset) {
    final currentRange = ref.read(analyticsTimeRangeProvider);
    final diff = currentRange.end.difference(currentRange.start).inDays;
    final actualDays = diff == 0 ? 1 : diff + 1;
    
    final newStart = currentRange.start.add(Duration(days: actualDays * offset));
    final newEnd = currentRange.end.add(Duration(days: actualDays * offset));
    
    ref.read(analyticsCustomDateRangeProvider.notifier).setCustomRange(
      DateTimeRange(start: newStart, end: newEnd),
    );
    state = AnalyticsTimeFilter.custom;
  }
}

final analyticsTimeFilterProvider = NotifierProvider<AnalyticsTimeFilterNotifier, AnalyticsTimeFilter>(
  () => AnalyticsTimeFilterNotifier(),
);

class AnalyticsCustomDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void setCustomRange(DateTimeRange? range) => state = range;
}

final analyticsCustomDateRangeProvider = NotifierProvider<AnalyticsCustomDateRangeNotifier, DateTimeRange?>(
  () => AnalyticsCustomDateRangeNotifier(),
);

// â”€â”€â”€ Time Range Calculator â”€â”€â”€

AnalyticsTimeRange _calculateTimeRange(AnalyticsTimeFilter filter, DateTimeRange? custom, bool isPrevious) {
  final now = DateTime.now();
  DateTime start;
  DateTime end;

  switch (filter) {
    case AnalyticsTimeFilter.today:
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      if (isPrevious) {
        start = start.subtract(const Duration(days: 1));
        end = end.subtract(const Duration(days: 1));
      }
      break;
    case AnalyticsTimeFilter.yesterday:
      start = DateTime(now.year, now.month, now.day - 1);
      end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59, 999);
      if (isPrevious) {
        start = start.subtract(const Duration(days: 1));
        end = end.subtract(const Duration(days: 1));
      }
      break;
    case AnalyticsTimeFilter.last7Days:
      start = DateTime(now.year, now.month, now.day - 6);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      if (isPrevious) {
        start = start.subtract(const Duration(days: 7));
        end = end.subtract(const Duration(days: 7));
      }
      break;
    case AnalyticsTimeFilter.currentWeek:
      int toMonday = now.weekday - DateTime.monday;
      start = DateTime(now.year, now.month, now.day - toMonday);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      if (isPrevious) {
        start = start.subtract(const Duration(days: 7));
        end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
      }
      break;
    case AnalyticsTimeFilter.lastWeek:
      int toMonday2 = now.weekday - DateTime.monday;
      start = DateTime(now.year, now.month, now.day - toMonday2 - 7);
      end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
      if (isPrevious) {
        start = start.subtract(const Duration(days: 7));
        end = end.subtract(const Duration(days: 7));
      }
      break;
    case AnalyticsTimeFilter.currentMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      if (isPrevious) {
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
      }
      break;
    case AnalyticsTimeFilter.lastMonth:
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
      if (isPrevious) {
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month - 1, 0, 23, 59, 59, 999);
      }
      break;
    case AnalyticsTimeFilter.currentYear:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      if (isPrevious) {
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59, 999);
      }
      break;
    case AnalyticsTimeFilter.custom:
      if (custom != null) {
        start = DateTime(custom.start.year, custom.start.month, custom.start.day);
        end = DateTime(custom.end.year, custom.end.month, custom.end.day, 23, 59, 59, 999);
        if (isPrevious) {
          final diff = end.difference(start);
          start = start.subtract(diff).subtract(const Duration(milliseconds: 1));
          end = end.subtract(diff).subtract(const Duration(milliseconds: 1));
        }
      } else {
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      }
      break;
  }
  return AnalyticsTimeRange(start: start, end: end, filter: filter);
}

final analyticsTimeRangeProvider = Provider<AnalyticsTimeRange>((ref) {
  return _calculateTimeRange(
    ref.watch(analyticsTimeFilterProvider),
    ref.watch(analyticsCustomDateRangeProvider),
    false,
  );
});

final analyticsPreviousTimeRangeProvider = Provider<AnalyticsTimeRange>((ref) {
  return _calculateTimeRange(
    ref.watch(analyticsTimeFilterProvider),
    ref.watch(analyticsCustomDateRangeProvider),
    true,
  );
});

// â”€â”€â”€ Current Streams â”€â”€â”€

final analyticsGamesStreamProvider = StreamProvider<List<GameSession>>((ref) async* {
  final tr = ref.watch(analyticsTimeRangeProvider);
  await Future.microtask(() {});
  yield* ref.watch(gamesRepositoryProvider).watchGamesByDateRange(tr.start, tr.end);
});

final analyticsQuickSalesStreamProvider = StreamProvider<List<QuickSale>>((ref) async* {
  final tr = ref.watch(analyticsTimeRangeProvider);
  await Future.microtask(() {});
  yield* ref.watch(quickSalesRepositoryProvider).watchQuickSalesByDateRange(tr.start, tr.end);
});

final analyticsPaymentsStreamProvider = StreamProvider<List<PaymentHistory>>((ref) async* {
  final tr = ref.watch(analyticsTimeRangeProvider);
  final clubId = ref.watch(clubIdProvider);
  final db = ref.watch(firestoreServiceProvider).db;
  
  if (clubId == null) {
    yield* const Stream.empty();
    return;
  }
  
  await Future.microtask(() {});
  yield* db
      .collectionGroup('payments')
      .where('clubId', isEqualTo: clubId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(tr.start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(tr.end))
      .snapshots()
      .map((snap) => snap.docs.map((d) => PaymentHistory.fromMap(d.id, d.data())).toList());
});

// â”€â”€â”€ Previous Streams â”€â”€â”€

final previousGamesStreamProvider = StreamProvider<List<GameSession>>((ref) async* {
  final tr = ref.watch(analyticsPreviousTimeRangeProvider);
  await Future.microtask(() {});
  yield* ref.watch(gamesRepositoryProvider).watchGamesByDateRange(tr.start, tr.end);
});

final previousQuickSalesStreamProvider = StreamProvider<List<QuickSale>>((ref) async* {
  final tr = ref.watch(analyticsPreviousTimeRangeProvider);
  await Future.microtask(() {});
  yield* ref.watch(quickSalesRepositoryProvider).watchQuickSalesByDateRange(tr.start, tr.end);
});

final previousPaymentsStreamProvider = StreamProvider<List<PaymentHistory>>((ref) async* {
  final tr = ref.watch(analyticsPreviousTimeRangeProvider);
  final clubId = ref.watch(clubIdProvider);
  final db = ref.watch(firestoreServiceProvider).db;
  
  if (clubId == null) {
    yield* const Stream.empty();
    return;
  }
  
  await Future.microtask(() {});
  yield* db
      .collectionGroup('payments')
      .where('clubId', isEqualTo: clubId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(tr.start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(tr.end))
      .snapshots()
      .map((snap) => snap.docs.map((d) => PaymentHistory.fromMap(d.id, d.data())).toList());
});

// â”€â”€â”€ Common Logic (Single Source of Truth) â”€â”€â”€

RevenueOverviewData _computeRevenue(List<GameSession> games, List<QuickSale> quickSales, List<PaymentHistory> payments, double outstanding) {
  double totalBilled = 0;
  double totalGameBilled = 0;
  double totalQuickSaleBilled = 0;
  double cashCollected = 0;
  double upiCollected = 0;
  double creditCreated = 0;
  double creditCollected = 0;

  for (final g in games) {
    if (g.status != TableStatus.available || g.paymentStatus == 'pending') continue;
    
    totalBilled += (g.grandTotal ?? 0.0);
    totalGameBilled += (g.grandTotal ?? 0.0);
    
    final ppm = g.playerPaymentMethods;
    if (ppm != null && ppm.isNotEmpty) {
      for (final kv in ppm.entries) {
        final amount = g.playerLiabilities?[kv.key] ?? 0.0;
        if (kv.value == PaymentMethod.cash) cashCollected += amount;
        else if (kv.value == PaymentMethod.upi) upiCollected += amount;
        else if (kv.value == PaymentMethod.credit) creditCreated += amount;
      }
    } else {
      final method = g.paymentMethod ?? PaymentMethod.cash;
      if (method == PaymentMethod.cash) cashCollected += (g.grandTotal ?? 0.0);
      else if (method == PaymentMethod.upi) upiCollected += (g.grandTotal ?? 0.0);
      else if (method == PaymentMethod.credit) creditCreated += (g.grandTotal ?? 0.0);
    }
  }

  for (final q in quickSales) {
    totalBilled += q.totalAmount;
    totalQuickSaleBilled += q.totalAmount;
    
    final method = q.paymentMethod;
    if (method == PaymentMethod.cash) cashCollected += q.totalAmount;
    else if (method == PaymentMethod.upi) upiCollected += q.totalAmount;
    else if (method == PaymentMethod.credit) creditCreated += q.totalAmount;
  }

  for (final p in payments) {
    creditCollected += p.amountPaid;
  }

  return RevenueOverviewData(
    totalBilled: totalBilled,
    cashCollected: cashCollected,
    upiCollected: upiCollected,
    creditCreated: creditCreated,
    creditCollected: creditCollected,
    outstandingCredit: outstanding,
    totalGameBilled: totalGameBilled,
    totalQuickSaleBilled: totalQuickSaleBilled,
  );
}

String _getTrendLabel(DateTime date, AnalyticsTimeFilter filter) {
  switch (filter) {
    case AnalyticsTimeFilter.today:
    case AnalyticsTimeFilter.yesterday:
      return DateFormat('ha').format(date); 
    case AnalyticsTimeFilter.last7Days:
    case AnalyticsTimeFilter.currentWeek:
    case AnalyticsTimeFilter.lastWeek:
      return DateFormat('EEE').format(date); 
    case AnalyticsTimeFilter.currentMonth:
    case AnalyticsTimeFilter.lastMonth:
      return DateFormat('d MMM').format(date); 
    case AnalyticsTimeFilter.currentYear:
      return DateFormat('MMM').format(date); 
    case AnalyticsTimeFilter.custom:
      return DateFormat('d MMM').format(date);
  }
}

// â”€â”€â”€ Complete Analytics Provider â”€â”€â”€

final completeAnalyticsProvider = Provider<CompleteAnalyticsData>((ref) {
  final timeRange = ref.watch(analyticsTimeRangeProvider);
  final outstanding = ref.watch(totalOutstandingCreditProvider);
  
  final games = ref.watch(analyticsGamesStreamProvider).value ?? [];
  final quickSales = ref.watch(analyticsQuickSalesStreamProvider).value ?? [];
  final payments = ref.watch(analyticsPaymentsStreamProvider).value ?? [];
  
  final prevGames = ref.watch(previousGamesStreamProvider).value ?? [];
  final prevQuickSales = ref.watch(previousQuickSalesStreamProvider).value ?? [];
  final prevPayments = ref.watch(previousPaymentsStreamProvider).value ?? [];
  
  final inventoryList = ref.watch(inventoryItemsProvider).value ?? [];
  final allCustomers = ref.watch(allCustomersProvider).value ?? [];

  final revenueOverview = _computeRevenue(games, quickSales, payments, outstanding);
  final prevOverview = _computeRevenue(prevGames, prevQuickSales, prevPayments, outstanding);

  // Constants for calculations
  final daysInRange = timeRange.end.difference(timeRange.start).inDays;
  final effectiveDays = daysInRange == 0 ? 1 : daysInRange;
  final operatingHoursPerDay = 14.0; // Assume 10am to 12am
  final totalOperatingMinutes = effectiveDays * operatingHoursPerDay * 60;

  // Build product purchase price map for COGS
  final Map<String, double> productCostMap = {
    for (var p in inventoryList) p.id: p.purchasePrice
  };

  // Maps and Accumulators
  final Map<String, GameCategoryData> gameCatMap = {};
  double tpBilled = 0;
  double friendlyBilled = 0;
  int tpCount = 0;
  int friendlyCount = 0;
  double perMinBilled = 0;
  double perFrameBilled = 0;
  
  final Map<String, TablePerformanceItem> tablePerfMap = {};
  final Map<String, double> trendMap = {};
  final Map<String, double> creditTrendMap = {};
  
  final Map<int, int> hourGameCounts = {};
  final Map<int, double> hourRevenueMap = {};
  final Map<int, double> dayRevenueMap = {};
  
  final Set<String> uniqueCustomers = {};
  int totalDurationMinutesAllGames = 0;
  
  double totalCogs = 0;

  for (final g in games) {
    if (g.status != TableStatus.available || g.paymentStatus == 'pending') continue;
    
    // Revenue & Category
    final double gTotal = g.grandTotal ?? 0.0;
    
    final cat = gameCatMap.putIfAbsent(g.tableType.displayName, () => GameCategoryData(categoryName: g.tableType.displayName, totalBilled: 0, transactionCount: 0, averageTransactionValue: 0));
    gameCatMap[g.tableType.displayName] = GameCategoryData(
      categoryName: g.tableType.displayName,
      totalBilled: cat.totalBilled + gTotal,
      transactionCount: cat.transactionCount + 1,
      averageTransactionValue: (cat.totalBilled + gTotal) / (cat.transactionCount + 1),
    );
    
    // Duration & COGS
    final int durMins = g.activeSeconds ~/ 60;
    totalDurationMinutesAllGames += durMins;
    
    for (final order in g.orders) {
      final cost = productCostMap[order.productId] ?? 0.0;
      totalCogs += cost * order.quantity;
    }
    
    // Table Performance
    final tbl = tablePerfMap.putIfAbsent(g.tableId, () => TablePerformanceItem(
      tableId: g.tableId,
      tableName: g.tableName,
      tableType: g.tableType.displayName,
      sessionsCount: 0,
      totalBilled: 0,
      averageSessionValue: 0,
      totalOrdersRevenue: 0,
      totalDurationMinutes: 0,
      avgDurationMinutes: 0,
      utilizationPercent: 0,
      hourlyUsage: {},
      dailyUsage: {},
      revenuePerHour: 0,
      overtimeCount: 0,
    ));
    
    final tHourly = Map<int, int>.from(tbl.hourlyUsage);
    final h = (g.endTime ?? g.startTime).hour;
    tHourly[h] = (tHourly[h] ?? 0) + 1;
    
    final tDaily = Map<int, int>.from(tbl.dailyUsage);
    final d = (g.endTime ?? g.startTime).weekday;
    tDaily[d] = (tDaily[d] ?? 0) + 1;
    
    final int newDuration = tbl.totalDurationMinutes + durMins;
    final double newBilled = tbl.totalBilled + gTotal;
    
    tablePerfMap[g.tableId] = TablePerformanceItem(
      tableId: g.tableId,
      tableName: g.tableName,
      tableType: g.tableType.displayName,
      sessionsCount: tbl.sessionsCount + 1,
      totalBilled: newBilled,
      averageSessionValue: newBilled / (tbl.sessionsCount + 1),
      totalOrdersRevenue: tbl.totalOrdersRevenue + (g.ordersTotal ?? 0.0),
      totalDurationMinutes: newDuration,
      avgDurationMinutes: newDuration ~/ (tbl.sessionsCount + 1),
      utilizationPercent: (newDuration / totalOperatingMinutes) * 100,
      hourlyUsage: tHourly,
      dailyUsage: tDaily,
      revenuePerHour: newDuration > 0 ? (newBilled / (newDuration / 60)) : 0.0,
      overtimeCount: tbl.overtimeCount + ((g.overtimeCharge ?? 0) > 0 ? 1 : 0),
    );
    
    // Global Trends & Insights
    final dateObj = g.endTime ?? g.startTime;
    final label = _getTrendLabel(dateObj, timeRange.filter);
    trendMap[label] = (trendMap[label] ?? 0) + gTotal;
    
    hourGameCounts[h] = (hourGameCounts[h] ?? 0) + 1;
    hourRevenueMap[h] = (hourRevenueMap[h] ?? 0) + gTotal;
    dayRevenueMap[d] = (dayRevenueMap[d] ?? 0) + gTotal;
    
    for (var p in g.allPlayers) {
      uniqueCustomers.add(p.trim().toLowerCase());
    }
    
    if (g.matchType == MatchType.loserPays) { tpBilled += gTotal; tpCount++; }
    else { friendlyBilled += gTotal; friendlyCount++; }
    
    if (g.billingType == BillingType.perFrame) perFrameBilled += gTotal;
    else perMinBilled += gTotal;
  }

  // Quick Sales Products & COGS
  final Map<String, BestSellingProductItem> productMap = {};
  final Map<String, QuickSaleCategoryData> qsCatMap = {};

  for (final q in quickSales) {
    final label = _getTrendLabel(q.date, timeRange.filter);
    trendMap[label] = (trendMap[label] ?? 0) + q.totalAmount;
    
    final h = q.date.hour;
    final d = q.date.weekday;
    hourRevenueMap[h] = (hourRevenueMap[h] ?? 0) + q.totalAmount;
    dayRevenueMap[d] = (dayRevenueMap[d] ?? 0) + q.totalAmount;
    
    if (q.customerName != null && q.customerName!.isNotEmpty) {
      uniqueCustomers.add(q.customerName!.trim().toLowerCase());
    }
    
    for (final item in q.items) {
      final cost = productCostMap[item.productId] ?? 0.0;
      totalCogs += cost * item.quantity;
      
      final p = productMap.putIfAbsent(item.productId, () => BestSellingProductItem(productId: item.productId, productName: item.productName, unitsSold: 0, salesAmount: 0));
      productMap[item.productId] = BestSellingProductItem(
        productId: p.productId,
        productName: p.productName,
        unitsSold: p.unitsSold + item.quantity,
        salesAmount: p.salesAmount + (item.quantity * item.pricePerUnit),
      );
      
      final c = qsCatMap.putIfAbsent(item.category, () => QuickSaleCategoryData(categoryName: item.category, totalSales: 0, unitsSold: 0, transactionCount: 0, averageSaleValue: 0));
      qsCatMap[item.category] = QuickSaleCategoryData(
        categoryName: item.category,
        totalSales: c.totalSales + (item.quantity * item.pricePerUnit),
        unitsSold: c.unitsSold + item.quantity,
        transactionCount: c.transactionCount + 1,
        averageSaleValue: (c.totalSales + (item.quantity * item.pricePerUnit)) / (c.transactionCount + 1),
      );
    }
  }

  for (final pay in payments) {
    final label = _getTrendLabel(pay.date, timeRange.filter);
    creditTrendMap[label] = (creditTrendMap[label] ?? 0) + pay.amountPaid;
  }

  // Formatting series
  final trendSeries = trendMap.entries.map((e) => TimeSeriesPoint(label: e.key, value: e.value)).toList();
  final creditTrendSeries = creditTrendMap.entries.map((e) => TimeSeriesPoint(label: e.key, value: e.value)).toList();
  
  final peakHours = hourGameCounts.entries.map((e) {
    final dt = DateTime(2024, 1, 1, e.key);
    final label = DateFormat('h a').format(dt);
    return TimeSeriesPoint(label: label, value: e.value.toDouble(), count: e.value);
  }).toList()..sort((a, b) => b.value.compareTo(a.value));
  
  final prodList = productMap.values.toList()..sort((a,b) => b.salesAmount.compareTo(a.salesAmount));

  // Determine top/bottom tables and peak hours for insights
  final tableList = tablePerfMap.values.toList()..sort((a,b) => b.totalBilled.compareTo(a.totalBilled));
  
  String busiestHour = 'N/A';
  if (hourRevenueMap.isNotEmpty) {
    final bestH = hourRevenueMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    busiestHour = DateFormat('h a').format(DateTime(2024, 1, 1, bestH));
  }
  
  String slowestHour = 'N/A';
  if (hourRevenueMap.isNotEmpty) {
    final worstH = hourRevenueMap.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    slowestHour = DateFormat('h a').format(DateTime(2024, 1, 1, worstH));
  }
  
  String busiestDay = 'N/A';
  if (dayRevenueMap.isNotEmpty) {
    final bestD = dayRevenueMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    busiestDay = days[bestD - 1];
  }

  // Calculate new/repeat customers (using previous period unique names)
  final Set<String> prevUniqueCustomers = {};
  for (final g in prevGames) {
    for (var p in g.allPlayers) prevUniqueCustomers.add(p.trim().toLowerCase());
  }
  for (final q in prevQuickSales) {
    if (q.customerName != null && q.customerName!.isNotEmpty) {
      prevUniqueCustomers.add(q.customerName!.trim().toLowerCase());
    }
  }
  
  int repeatCust = 0;
  for (final c in uniqueCustomers) {
    if (prevUniqueCustomers.contains(c)) repeatCust++;
  }
  int newCust = uniqueCustomers.length - repeatCust;

  // Credit Pending Customers Count
  int pendingCustCount = allCustomers.where((c) => c.outstandingAmount > 0).length;

  // Inventory stats
  int lowStock = inventoryList.where((i) => i.isLowStock).length;
  int outOfStock = inventoryList.where((i) => i.isOutOfStock).length;
  double totalInvValue = inventoryList.fold(0.0, (sum, i) => sum + (i.currentStock * i.purchasePrice));

  final paymentShare = [
    if (revenueOverview.cashCollected > 0) CategoryShare(categoryName: 'Cash', amount: revenueOverview.cashCollected, percentage: (revenueOverview.cashCollected/revenueOverview.totalBilled)*100, color: AppColors.success),
    if (revenueOverview.upiCollected > 0) CategoryShare(categoryName: 'UPI', amount: revenueOverview.upiCollected, percentage: (revenueOverview.upiCollected/revenueOverview.totalBilled)*100, color: AppColors.info),
    if (revenueOverview.creditCreated > 0) CategoryShare(categoryName: 'Credit', amount: revenueOverview.creditCreated, percentage: (revenueOverview.creditCreated/revenueOverview.totalBilled)*100, color: AppColors.warning),
  ];
  
  final sourceShare = [
    if (revenueOverview.totalGameBilled > 0) CategoryShare(categoryName: 'Games', amount: revenueOverview.totalGameBilled, percentage: (revenueOverview.totalGameBilled/revenueOverview.totalBilled)*100, color: AppColors.primary),
    if (revenueOverview.totalQuickSaleBilled > 0) CategoryShare(categoryName: 'Quick Sales', amount: revenueOverview.totalQuickSaleBilled, percentage: (revenueOverview.totalQuickSaleBilled/revenueOverview.totalBilled)*100, color: AppColors.tertiary),
  ];

  return CompleteAnalyticsData(
    timeRange: timeRange,
    revenueOverview: revenueOverview,
    revenueTrendSeries: trendSeries,
    paymentMethodsShare: paymentShare,
    revenueSourceShare: sourceShare,
    gameAnalytics: GameAnalyticsData(
      categories: gameCatMap.values.toList(),
      totalGameSessions: games.length,
      tpBilled: tpBilled,
      friendlyBilled: friendlyBilled,
      tpCount: tpCount,
      friendlyCount: friendlyCount,
      perMinuteBilled: perMinBilled,
      perFrameBilled: perFrameBilled,
    ),
    tablePerformances: tableList,
    bestSellingProducts: prodList,
    quickSaleCategories: qsCatMap.values.toList(),
    creditAnalytics: CreditAnalyticsData(
      creditCreated: revenueOverview.creditCreated,
      creditCollected: revenueOverview.creditCollected,
      currentOutstanding: revenueOverview.outstandingCredit,
      numberOfCreditTransactions: payments.length,
      pendingCustomersCount: pendingCustCount,
      averageCreditAmount: payments.isNotEmpty ? (revenueOverview.creditCollected / payments.length) : 0,
    ),
    creditCollectionTrend: creditTrendSeries,
    peakBusinessHours: peakHours,
    periodComparison: PeriodComparisonData(
      currentPeriod: revenueOverview,
      previousPeriod: prevOverview,
    ),
    businessInsights: BusinessInsightsData(
      totalUniqueCustomers: uniqueCustomers.length,
      newCustomersThisPeriod: newCust,
      repeatCustomersThisPeriod: repeatCust,
      averageCustomerSpend: uniqueCustomers.isNotEmpty ? (revenueOverview.totalBilled / uniqueCustomers.length) : 0.0,
      averageSessionDuration: games.isNotEmpty ? (totalDurationMinutesAllGames / games.length) : 0.0,
      tableUtilizationRate: tableList.isNotEmpty ? (totalDurationMinutesAllGames / (totalOperatingMinutes * tableList.length)) * 100 : 0.0,
      busiestHour: busiestHour,
      slowestHour: slowestHour,
      busiestDay: busiestDay,
      bestPerformingTable: tableList.isNotEmpty ? tableList.first.tableName : 'N/A',
      worstPerformingTable: tableList.isNotEmpty ? tableList.last.tableName : 'N/A',
    ),
    inventoryAnalytics: InventoryAnalyticsData(
      totalProducts: inventoryList.length,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
      totalInventoryValue: totalInvValue,
      costOfGoodsSold: totalCogs,
      grossProfit: revenueOverview.totalBilled - totalCogs,
    ),
  );
});

