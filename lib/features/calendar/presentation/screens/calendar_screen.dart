import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/helpers/currency_helper.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_shadows.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/core/widgets/shared/date_navigation_header.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final gamesAsync = ref
        .watch(gamesRepositoryProvider)
        .watchAllGamesByDate(dateStr);
    final quickSalesAsync = ref
        .watch(quickSalesRepositoryProvider)
        .watchQuickSales(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Revenue'),
        actions: [const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          // Date Selector Header
          DateNavigationHeader(
            selectedDate: _selectedDate,
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
            },
          ),

          // Daily Revenue Summary Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isToday
                        ? "Today's Revenue Summary"
                        : "Daily Revenue Summary",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Combined earnings from active games and POS quick sales.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(24),

                  // Stream builder combination
                  StreamBuilder(
                    stream: gamesAsync,
                    builder: (context, gamesSnap) {
                      return StreamBuilder(
                        stream: quickSalesAsync,
                        builder: (context, quickSalesSnap) {
                          if (gamesSnap.connectionState ==
                                      ConnectionState.waiting &&
                                  !gamesSnap.hasData ||
                              quickSalesSnap.connectionState ==
                                      ConnectionState.waiting &&
                                  !quickSalesSnap.hasData) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: List.generate(
                                  3,
                                  (_) => const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: SkeletonLoader(
                                      height: 80,
                                      borderRadius: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final games = gamesSnap.data ?? [];
                          final quickSales = quickSalesSnap.data ?? [];

                          // Calculate Cash/UPI revenues
                          final gamesRevenue = games
                              .where((g) => g.status == TableStatus.available)
                              .fold(
                                0.0,
                                (sum, g) =>
                                    sum +
                                    (g.finalAmount ?? g.grandTotal ?? 0.0),
                              );

                          final quickSalesRevenue = quickSales.fold(
                            0.0,
                            (sum, s) => sum + s.totalAmount,
                          );

                          final totalRevenue = gamesRevenue + quickSalesRevenue;

                          // Credit tracking for information
                          final gamesCredit = games
                              .where(
                                (g) =>
                                    g.status == TableStatus.available &&
                                    g.paymentMethod == PaymentMethod.credit,
                              )
                              .fold(
                                0.0,
                                (sum, g) =>
                                    sum +
                                    (g.finalAmount ?? g.grandTotal ?? 0.0),
                              );
                          final quickSalesCredit = quickSales
                              .where(
                                (s) => s.paymentMethod == PaymentMethod.credit,
                              )
                              .fold(0.0, (sum, s) => sum + s.totalAmount);

                          return Column(
                            children: [
                              // Hero Total Revenue Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppShadows.large,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Revenue',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'Cash & UPI',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(8),
                                    Text(
                                      CurrencyHelper.formatWhole(
                                        totalRevenue,
                                        currency,
                                      ),
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              const Gap(20),

                              // Breakdown Row: Games vs Quick Sales
                              Row(
                                children: [
                                  Expanded(
                                    child: _RevenueCategoryCard(
                                      title: 'Games Income',
                                      amount: CurrencyHelper.formatWhole(
                                        gamesRevenue,
                                        currency,
                                      ),
                                      countText:
                                          '${games.where((g) => g.status == TableStatus.available).length} sessions',
                                      icon: Icons.sports_esports,
                                      iconColor: AppColors.primary,
                                    ),
                                  ),
                                  const Gap(16),
                                  Expanded(
                                    child: _RevenueCategoryCard(
                                      title: 'Quick Sales Income',
                                      amount: CurrencyHelper.formatWhole(
                                        quickSalesRevenue,
                                        currency,
                                      ),
                                      countText: '${quickSales.length} orders',
                                      icon: Icons.inventory_2,
                                      iconColor: AppColors.tertiary,
                                    ),
                                  ),
                                ],
                              ),

                              const Gap(24),

                              // Additional Information (Outstanding Credits recorded on selected date)
                              if (gamesCredit > 0 || quickSalesCredit > 0)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.creditStatus.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.creditStatus.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppColors.creditStatus,
                                        size: 24,
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Included Credit Sales Today: ${CurrencyHelper.formatWhole(gamesCredit + quickSalesCredit, currency)}',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.creditStatus,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              'These credit amounts are included in your total revenue above.',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCategoryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String countText;
  final IconData icon;
  final Color iconColor;

  const _RevenueCategoryCard({
    required this.title,
    required this.amount,
    required this.countText,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                countText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(4),
          Text(
            amount,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
