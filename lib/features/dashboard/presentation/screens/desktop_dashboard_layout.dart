import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:go_router/go_router.dart';

import 'package:snooker_club/features/dashboard/providers/financial_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/running_tables_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/available_tables_screen.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/dashboard/presentation/screens/dashboard_screen.dart';

class DesktopDashboardLayout extends ConsumerWidget {
  final String employeeName;

  const DesktopDashboardLayout({super.key, required this.employeeName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          const Gap(24),
          _buildStatsRow(context, ref),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildFinancialBreakdown(context, ref),
              ),
              const Gap(16),
              Expanded(
                flex: 1,
                child: _buildQuickAccess(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final now = ref.watch(realTimeClockProvider).value ?? DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Gap(4),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B8EA3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(financialSummaryProvider);
    final runningCount = ref.watch(runningTablesCountProvider);
    final availableCount = ref.watch(availableTablesCountProvider);
    final qsCount = ref.watch(todaysQuickSalesCountProvider);

    final summary = asyncSummary.value;
    final currencySymbol = ref.watch(currencyProvider).symbol;
    
    final totalBilled = summary?.totalBilled ?? 0;
    final cashCollected = summary?.cashCollected ?? 0;
    final outstandingCredit = summary?.outstandingCredit ?? 0;

    return Row(
      children: [
        _buildStatCard(
          title: 'Total billed',
          value: '$currencySymbol${totalBilled.toStringAsFixed(0)}',
          valueColor: const Color(0xFF6C6FEF),
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF6C6FEF),
          onTap: () => context.push(RouteNames.financialReview),
        ),
        const Gap(16),
        _buildStatCard(
          title: 'Cash collected',
          value: '$currencySymbol${cashCollected.toStringAsFixed(0)}',
          valueColor: Colors.white,
          icon: Icons.payments,
          color: const Color(0xFF5DCAA5),
          onTap: () => context.push(RouteNames.financialReview),
        ),
        const Gap(16),
        _buildStatCard(
          title: 'Outstanding credit',
          value: '$currencySymbol${outstandingCredit.toStringAsFixed(0)}',
          valueColor: Colors.white,
          icon: Icons.credit_card,
          color: const Color(0xFFE24B4A),
          onTap: () => context.push(RouteNames.credit),
        ),
        const Gap(16),
        _buildStatCard(
          title: 'Running tables',
          value: runningCount.toString(),
          valueColor: Colors.white,
          icon: Icons.chair,
          color: const Color(0xFF6C6FEF),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const RunningTablesScreen()));
          },
        ),
        const Gap(16),
        _buildStatCard(
          title: 'Available tables',
          value: availableCount.toString(),
          valueColor: Colors.white,
          icon: Icons.check_circle_outline,
          color: const Color(0xFF5DCAA5),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const AvailableTablesScreen()));
          },
        ),
        const Gap(16),
        _buildStatCard(
          title: 'Quick sales today',
          value: qsCount.toString(),
          valueColor: Colors.white,
          icon: Icons.shopping_cart,
          color: const Color(0xFF6C6FEF),
          onTap: () => context.push(RouteNames.quickSales),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF12141F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(icon, size: 14, color: color),
                  ),
                ),
                const Gap(8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8B8EA3)),
                ),
                const Gap(2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialBreakdown(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(financialSummaryProvider);
    final summary = asyncSummary.value;
    final currencySymbol = ref.watch(currencyProvider).symbol;

    final cash = summary?.cashCollected ?? 0;
    final upi = summary?.upiCollected ?? 0;
    final creditColl = summary?.creditCollected ?? 0;
    
    final totalColl = cash + upi + creditColl;
    
    double cashPct = totalColl > 0 ? (cash / totalColl) : 0;
    double upiPct = totalColl > 0 ? (upi / totalColl) : 0;
    double creditPct = totalColl > 0 ? (creditColl / totalColl) : 0;

    final creditCreated = summary?.creditCreated ?? 0;
    final outstandingCredit = summary?.outstandingCredit ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12141F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.financialReview),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(Icons.chevron_right, size: 15, color: Color(0xFF8B8EA3)),
                ),
              ),
            ],
          ),
          const Gap(14),
          const Text(
            'Collections',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B8EA3)),
          ),
          const Gap(8),
          
          _buildProgressBar('Cash', '$currencySymbol${cash.toStringAsFixed(0)}', cashPct, const Color(0xFF5DCAA5)),
          const Gap(8),
          _buildProgressBar('UPI', '$currencySymbol${upi.toStringAsFixed(0)}', upiPct, const Color(0xFF6C6FEF)),
          const Gap(14),
          _buildProgressBar('Credit', '$currencySymbol${creditColl.toStringAsFixed(0)}', creditPct, const Color(0xFFE24B4A)),
          
          const Gap(12),
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          const Gap(12),
          
          const Text(
            'Credit activity',
            style: TextStyle(fontSize: 11, color: Color(0xFF8B8EA3)),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Credit created', style: TextStyle(fontSize: 13, color: Color(0xFFC9CBE0))),
              Text('$currencySymbol${creditCreated.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFFF0B429))),
            ],
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Outstanding credit', style: TextStyle(fontSize: 13, color: Color(0xFFC9CBE0))),
              Text('$currencySymbol${outstandingCredit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFFE24B4A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, String value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFC9CBE0))),
            Text(value, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
        const Gap(4),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D29),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Quick access',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
        _buildQuickAccessTile(
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF6C6FEF),
          iconBg: const Color(0xFF6C6FEF).withValues(alpha: 0.15),
          title: 'Reservations & bookings',
          subtitle: 'Manage table reservations',
          onTap: () => context.push(RouteNames.bookings),
        ),
        const Gap(10),
        _buildQuickAccessTile(
          icon: Icons.settings,
          iconColor: const Color(0xFFC9CBE0),
          iconBg: const Color(0xFF1A1D29),
          title: 'Settings',
          subtitle: 'App config',
          onTap: () => context.push(RouteNames.settings),
        ),
        const Gap(10),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const InventoryStatusScreen()));
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF12141F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF5DCAA5)),
                  const Gap(10),
                  const Text('Inventory status: ', style: TextStyle(fontSize: 12, color: Color(0xFFC9CBE0))),
                  const Text('All good', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5DCAA5))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF12141F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Icon(icon, size: 17, color: iconColor)),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    const Gap(1),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8B8EA3))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 15, color: Color(0xFF8B8EA3)),
            ],
          ),
        ),
      ),
    );
  }
}
