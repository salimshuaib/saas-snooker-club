import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_spacing.dart';
import 'package:snooker_club/core/widgets/cards/glass_card.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/analytics/presentation/widgets/analytics_time_filter_bar.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/reports/services/export_service.dart';
import 'package:gap/gap.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final analyticsData = getCompleteAnalyticsData(ref);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Export Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AnalyticsTimeFilterBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Preview Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    _PreviewCard(
                      title: 'Total Billed',
                      amount: analyticsData.revenueOverview.totalBilled,
                      currency: currency.symbol,
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.blue,
                    ),
                    const Gap(AppSpacing.sm),
                    _PreviewCard(
                      title: 'Cash Collected',
                      amount: analyticsData.revenueOverview.cashCollected,
                      currency: currency.symbol,
                      icon: Icons.money_rounded,
                      color: Colors.green,
                    ),
                    const Gap(AppSpacing.sm),
                    _PreviewCard(
                      title: 'Outstanding Credit',
                      amount: analyticsData.revenueOverview.outstandingCredit,
                      currency: currency.symbol,
                      icon: Icons.credit_score_rounded,
                      color: Colors.red,
                    ),
                    const Gap(AppSpacing.xl),
                    const Text(
                      'Export As',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _ExportButton(
                            title: 'PDF Document',
                            subtitle: 'Professional printable report',
                            icon: Icons.picture_as_pdf_rounded,
                            color: Colors.redAccent,
                            onTap: () =>
                                ExportService.exportToPdf(context, ref),
                          ),
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: _ExportButton(
                            title: 'Excel Workbook',
                            subtitle: 'Detailed multi-sheet data',
                            icon: Icons.table_chart_rounded,
                            color: Colors.green,
                            onTap: () =>
                                ExportService.exportToExcel(context, ref),
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.md),
                    _ExportButton(
                      title: 'CSV Export',
                      subtitle: 'Raw game data for spreadsheets',
                      icon: Icons.file_present_rounded,
                      color: Colors.blueAccent,
                      onTap: () => ExportService.exportToCsv(context, ref),
                    ),
                    const Gap(AppSpacing.md),
                    _ExportButton(
                      title: 'Due Credit Report (PDF)',
                      subtitle: 'List of all players with outstanding credit',
                      icon: Icons.money_off_csred_rounded,
                      color: Colors.orange,
                      onTap: () =>
                          ExportService.exportDueCreditToPdf(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final double amount;
  final String currency;
  final IconData icon;
  final Color color;

  const _PreviewCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: AppSpacing.paddingAllMd,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.title,
    required this.subtitle,
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
        padding: AppSpacing.paddingAllMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Gap(AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
