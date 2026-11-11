import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_spacing.dart';
import 'package:snooker_club/core/widgets/cards/glass_card.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_time_filter_bar.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/reports/services/export_service.dart';
import 'package:snooker_club/core/widgets/cards/not_authorized_card.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStaff = ref.watch(currentStaffProvider).value;
    if (currentStaff?.isLimitedAccess == true) {
      return const NotAuthorizedScreen(
        title: 'Not Authorized',
        message: 'You have Limited Access. Viewing and downloading club financial reports is restricted. Please contact your club owner for access.',
      );
    }

    final currency = ref.watch(currencyProvider);
    final analyticsData = getCompleteAnalyticsData(ref);
    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? <FloorModel>[];
    final selectedFloorId = ref.watch(selectedFloorIdProvider);

    final totalBilled = analyticsData.revenueOverview.totalBilled;
    final totalExpenses = analyticsData.revenueOverview.totalExpenses;
    final netEarnings = analyticsData.revenueOverview.netEarnings;
    final cashCollected = analyticsData.revenueOverview.cashCollected;
    final upiCollected = analyticsData.revenueOverview.upiCollected;
    final outstandingCredit = analyticsData.revenueOverview.outstandingCredit;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text(
          'Reports & Data Export',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Filter Bar
            const AnalyticsTimeFilterBar(),

            // Multi-Floor Selector (if club has multiple floors)
            if (hasFloors && floors.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 6,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedFloorId != null
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 18,
                        color: selectedFloorId != null
                            ? AppColors.primary
                            : Colors.white70,
                      ),
                      const Gap(8),
                      const Text(
                        'Floor Filter:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedFloorId,
                          dropdownColor: AppColors.darkSurface,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Floors (Consolidated)'),
                            ),
                            ...floors.map(
                              (f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(f.name),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            ref
                                .read(selectedFloorIdProvider.notifier)
                                .selectFloor(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Executive P&L Financial Preview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Financial Snapshot',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'P&L Overview',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),
                          // Row 1: Gross Billed, Expenses, Net Profit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryKpi(
                                label: 'Gross Revenue',
                                value: '${currency.symbol}${totalBilled.toStringAsFixed(0)}',
                                color: Colors.blueAccent,
                              ),
                              Container(
                                width: 1,
                                height: 35,
                                color: Colors.white10,
                              ),
                              _buildSummaryKpi(
                                label: 'Club Expenses',
                                value: '${currency.symbol}${totalExpenses.toStringAsFixed(0)}',
                                color: AppColors.error,
                              ),
                              Container(
                                width: 1,
                                height: 35,
                                color: Colors.white10,
                              ),
                              _buildSummaryKpi(
                                label: 'Net Profit',
                                value: '${currency.symbol}${netEarnings.toStringAsFixed(0)}',
                                color: netEarnings >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ],
                          ),
                          const Gap(14),
                          const Divider(color: Colors.white10, height: 1),
                          const Gap(12),
                          // Row 2: Cash, UPI, Credit Due
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat(
                                label: '💵 Cash Paid',
                                value: '${currency.symbol}${cashCollected.toStringAsFixed(0)}',
                                color: AppColors.primary,
                              ),
                              Container(
                                width: 1,
                                height: 26,
                                color: Colors.white10,
                              ),
                              _buildMiniStat(
                                label: '📱 UPI Paid',
                                value: '${currency.symbol}${upiCollected.toStringAsFixed(0)}',
                                color: AppColors.secondary,
                              ),
                              Container(
                                width: 1,
                                height: 26,
                                color: Colors.white10,
                              ),
                              _buildMiniStat(
                                label: '💳 Credit Due',
                                value: '${currency.symbol}${outstandingCredit.toStringAsFixed(0)}',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(AppSpacing.xl),

                    // Section 1: Professional PDF Reports
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Business PDF Reports',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'In-App Viewer • Print • Share',
                            style: TextStyle(fontSize: 10, color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),

                    // Report 1: Financial & Net Revenue Report (PDF)
                    _ReportCard(
                      title: 'Financial & Revenue Report',
                      tag: 'P&L Statement',
                      description:
                          'Complete Profit & Loss statement based on selected date range and floor filter. It details gross game earnings, deducts all club operating expenses, calculates net profit or loss, and details payment channels.',
                      bulletPoints: const [
                        'Gross billing vs. operating expenses audit',
                        'Net profit / loss calculation for selected period',
                        'Multi-floor revenue distribution (if applicable)',
                        'Cash, UPI & Credit collection totals',
                      ],
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => ExportService.exportToPdf(context, ref),
                    ),
                    const Gap(AppSpacing.md),

                    // Report 2: Game Performance Report (PDF)
                    _ReportCard(
                      title: 'Game Performance & Tables',
                      tag: 'Tables & Playtime',
                      description:
                          'Deep-dive operational analytics on table usage and club playtime. Measures table occupancy rates, active playtime duration, average game length, and provides a full chronological session log.',
                      bulletPoints: const [
                        'Occupancy rate & active hours per table',
                        'Floor-wise table distribution & utilization',
                        'Completed game sessions with billing amounts',
                        'Peak hours & playtime patterns',
                      ],
                      icon: Icons.sports_esports_rounded,
                      color: const Color(0xFF06B6D4),
                      onTap: () =>
                          ExportService.exportGamePerformancePdf(context, ref),
                    ),
                    const Gap(AppSpacing.md),

                    // Report 3: Players Activity & Accounts (PDF)
                    _ReportCard(
                      title: 'Players Activity & Accounts',
                      tag: 'Players & Spending',
                      description:
                          'Comprehensive customer engagement and ledger analysis. Displays customer spending rankings, visit frequencies, recent game activities, and individual khata credit/debit records.',
                      bulletPoints: const [
                        'Customer spending leaderboard & rankings',
                        'Total visit frequency & active games count',
                        'Customer khata balances and credit ledger',
                        'Registered phone numbers for relationship management',
                      ],
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          ExportService.exportPlayersReportPdf(context, ref),
                    ),
                    const Gap(AppSpacing.md),

                    // Report 4: Club Operating Expenses (PDF)
                    _ReportCard(
                      title: 'Club Operating Expenses',
                      tag: 'Expenses Audit',
                      description:
                          'Itemized operating expense report for complete financial transparency. Categorizes every expense by operational type, highlights cash vs. online UPI vs. vendor credit payments, and lists all settled entries.',
                      bulletPoints: const [
                        'Category-wise expense breakdown (utilities, supplies, repairs)',
                        'Cash, UPI & Credit vendor payment breakdown',
                        'Itemized audit log with timestamps and staff notes',
                        'Settled credit transactions summary',
                      ],
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFFF43F5E),
                      onTap: () =>
                          ExportService.exportExpensesReportPdf(context, ref),
                    ),
                    const Gap(AppSpacing.md),

                    // Report 5: Outstanding Due Credit Report (PDF)
                    _ReportCard(
                      title: 'Outstanding Due Credit',
                      tag: 'Debt Recovery',
                      description:
                          'Dedicated debt recovery ledger for pending customer credit balances. Details every customer account with outstanding balances, last payment dates, and registered phone numbers for quick recovery follow-ups.',
                      bulletPoints: const [
                        'All accounts with active pending credit dues',
                        'Customer names and registered phone numbers',
                        'Total outstanding liability summary',
                        'Direct communication contact for recovery follow-up',
                      ],
                      icon: Icons.credit_score_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () =>
                          ExportService.exportDueCreditToPdf(context, ref),
                    ),
                    const Gap(AppSpacing.md),

                    // Report 6: Employee Details & Performance (PDF)
                    _ReportCard(
                      title: 'Employee Details & Performance',
                      tag: 'Staff Audit',
                      description:
                          'Comprehensive staff performance and accountability report. Evaluates shift attendance hours, games started & billed, quick sales revenue generated, and customer credit (khata) authorized. Audit an individual staff member or the whole roster.',
                      bulletPoints: const [
                        'Select individual employee or full team audit',
                        'Attendance shifts logged & total active working hours',
                        'Games started count, playtime minutes & table billing',
                        'Quick sales counter deals, items sold & revenue',
                        'Customer credit (khata) authorized breakdown',
                      ],
                      icon: Icons.badge_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () => _showEmployeeSelectionSheet(context, ref),
                    ),

                    const Gap(AppSpacing.xl),

                    // Section 2: Data Spreadsheets (Excel & CSV)
                    const Text(
                      'Data Spreadsheets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(AppSpacing.md),

                    Row(
                      children: [
                        // Excel Workbook
                        Expanded(
                          child: _SpreadsheetButton(
                            title: 'Excel Workbook',
                            subtitle: '6-in-1 multi-sheet (.xlsx)',
                            description:
                                'Exports a comprehensive 6-in-1 multi-sheet Excel spreadsheet containing executive P&L metrics, raw game session logs, player profiles & dues, itemized expenses, and floor table analytics.',
                            bulletPoints: const [
                              'Summary KPIs & P&L tab',
                              'Complete games session ledger',
                              'Customer khata & credit balances',
                              'Itemized operating expense logs',
                            ],
                            icon: Icons.table_chart_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () =>
                                ExportService.exportToExcel(context, ref),
                          ),
                        ),
                        const Gap(AppSpacing.md),
                        // CSV Raw Export
                        Expanded(
                          child: _SpreadsheetButton(
                            title: 'Raw Games CSV',
                            subtitle: 'Session records (.csv)',
                            description:
                                'Raw tabular session logs exported in universal CSV format for spreadsheet apps and database integration.',
                            bulletPoints: const [
                              'Universal comma-separated format (.csv)',
                              'Session start/stop times and durations',
                              'Table names, billings & discounts',
                              'Ready for Excel or Google Sheets',
                            ],
                            icon: Icons.file_present_rounded,
                            color: const Color(0xFF3B82F6),
                            onTap: () =>
                                ExportService.exportToCsv(context, ref),
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpi({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

void _showReportInfoSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String tag,
  required IconData icon,
  required Color color,
  required IconData actionIcon,
  required String actionLabel,
  required VoidCallback onAction,
  List<String>? bulletPoints,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E212A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull indicator
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(14),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const Gap(14),
                    const Divider(color: Colors.white10, height: 1),
                    const Gap(14),
                    const Text(
                      'What this report includes:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
                      const Gap(12),
                      ...bulletPoints.map(
                        (bp) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: color,
                                  size: 14,
                                ),
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  bp,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Gap(20),
                    // Action button: View / Download Report
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onAction();
                        },
                        icon: Icon(actionIcon, size: 18),
                        label: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showEmployeeSelectionSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Gap(2),
                          Text(
                            'Select an employee or export full team audit',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Gap(12),
              const Divider(color: Colors.white10, height: 1),
              const Gap(12),

              // All Employees Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ExportService.exportStaffPerformancePdf(context, ref);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF818CF8),
                            size: 20,
                          ),
                        ),
                        const Gap(12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Employees (Full Team Audit)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Gap(2),
                              Text(
                                'Roster overview with separate individual breakdown',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFF818CF8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Gap(14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'OR SELECT INDIVIDUAL EMPLOYEE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),

              // Staff List Stream
              Flexible(
                child: Consumer(
                  builder: (context, ref, _) {
                    final staffAsync = ref.watch(teamMembersStreamProvider);
                    return staffAsync.when(
                      data: (members) {
                        if (members.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No team members found in this club.',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: members.length,
                          separatorBuilder: (_, _) => const Gap(8),
                          itemBuilder: (ctx, i) {
                            final m = members[i];
                            final initial = m.name.isNotEmpty
                                ? m.name[0].toUpperCase()
                                : '?';
                            return InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                ExportService.exportStaffPerformancePdf(
                                  context,
                                  ref,
                                  selectedStaffMember: m,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  m.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Gap(6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  m.role.name.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (m.isLimitedAccess) ...[
                                                const Gap(4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'LIMITED',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      color: AppColors.warning,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (m.email.isNotEmpty) ...[
                                            const Gap(2),
                                            Text(
                                              m.email,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white30,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading staff: $err',
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      );
    },
  );
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String tag;
  final String description;
  final List<String>? bulletPoints;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.tag,
    required this.description,
    this.bulletPoints,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(4),
            IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white60,
                size: 20,
              ),
              tooltip: 'Report info',
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _showReportInfoSheet(
                context,
                title: title,
                description: description,
                tag: tag,
                icon: icon,
                color: color,
                actionIcon: Icons.picture_as_pdf_rounded,
                actionLabel: 'View / Download PDF',
                bulletPoints: bulletPoints,
                onAction: onTap,
              ),
            ),
            const Gap(2),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white30,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpreadsheetButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<String> bulletPoints;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SpreadsheetButton({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bulletPoints,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  tooltip: 'Export info',
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => _showReportInfoSheet(
                    context,
                    title: title,
                    description: description,
                    tag: 'Spreadsheet',
                    icon: icon,
                    color: color,
                    actionIcon: Icons.download_rounded,
                    actionLabel: 'Export & Download',
                    bulletPoints: bulletPoints,
                    onAction: onTap,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
