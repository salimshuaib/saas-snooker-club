// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/reports/presentation/screens/pdf_viewer_screen.dart';
import 'package:snooker_club/features/team/domain/models/attendance_log.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class StaffPerformanceStats {
  final StaffMember staff;
  final int shiftsCount;
  final double totalHoursWorked;
  final List<AttendanceLog> shifts;
  final int gamesStartedCount;
  final double totalGameBilling;
  final int totalGameMinutes;
  final List<GameSession> games;
  final int quickSalesCount;
  final double totalQuickSalesRevenue;
  final int quickSalesItemsCount;
  final List<QuickSale> quickSales;
  final double totalCreditGiven;
  final double totalRevenueGenerated;

  const StaffPerformanceStats({
    required this.staff,
    required this.shiftsCount,
    required this.totalHoursWorked,
    required this.shifts,
    required this.gamesStartedCount,
    required this.totalGameBilling,
    required this.totalGameMinutes,
    required this.games,
    required this.quickSalesCount,
    required this.totalQuickSalesRevenue,
    required this.quickSalesItemsCount,
    required this.quickSales,
    required this.totalCreditGiven,
    required this.totalRevenueGenerated,
  });
}

class ExportService {
  // ─── Font Helper ───────────────────────────────────────────────────────────
  static Future<pw.ThemeData> _getPdfTheme() async {
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      return pw.ThemeData.withFont(base: font, bold: boldFont);
    } catch (_) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }

  // ─── PDF Viewer Navigation ────────────────────────────────────────────────
  static void _openPdfViewer(
    BuildContext context, {
    required String title,
    required Uint8List pdfBytes,
    required String fileName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: title,
          pdfBytes: pdfBytes,
          fileName: fileName,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. FINANCIAL & NET REVENUE REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportToPdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final range = ref.read(analyticsTimeRangeProvider);
      final analyticsData = getCompleteAnalyticsData(ref);
      final selectedFloorId = ref.read(selectedFloorIdProvider);
      final floors = ref.read(floorsProvider).value ?? <FloorModel>[];
      final hasFloors = ref.read(hasFloorsProvider);
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final allGames =
          ref.read(analyticsGamesStreamProvider).value ?? <GameSession>[];
      final allQuickSales =
          ref.read(analyticsQuickSalesStreamProvider).value ?? <QuickSale>[];
      final allExpenses =
          ref.read(analyticsExpensesStreamProvider).value ?? <Expense>[];

      final theme = await _getPdfTheme();
      final pdf = pw.Document();

      final totalBilled = analyticsData.revenueOverview.totalBilled;
      final totalExpenses = analyticsData.revenueOverview.totalExpenses;
      final netEarnings = analyticsData.revenueOverview.netEarnings;
      final cashCollected = analyticsData.revenueOverview.cashCollected;
      final upiCollected = analyticsData.revenueOverview.upiCollected;
      final creditCreated = analyticsData.revenueOverview.creditCreated;
      final creditCollected = analyticsData.revenueOverview.creditCollected;
      final outstandingCredit = analyticsData.revenueOverview.outstandingCredit;

      String floorLabel = 'All Floors (Consolidated)';
      if (selectedFloorId != null) {
        final fMatch = floors.where((f) => f.id == selectedFloorId);
        if (fMatch.isNotEmpty) floorLabel = fMatch.first.name;
      }

      final dateStr =
          '${DateFormat("dd MMM yyyy").format(range.start)} - ${DateFormat("dd MMM yyyy").format(range.end)}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Financial Statement & Net Revenue Report',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Scope: $floorLabel',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date Range: $dateStr',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 14),

              // KPI Summary Row
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfKpi(
                      label: 'Gross Billed',
                      value: '$currency${totalBilled.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFF0284C7),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Club Expenses',
                      value: '$currency${totalExpenses.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFFE11D48),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Net Profit',
                      value: '$currency${netEarnings.toStringAsFixed(0)}',
                      color: netEarnings >= 0
                          ? const PdfColor.fromInt(0xFF059669)
                          : const PdfColor.fromInt(0xFFE11D48),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Financial Breakdown Table
              pw.Text(
                'Revenue & Collections Breakdown',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                data: <List<String>>[
                  ['Metric', 'Amount', 'Description'],
                  [
                    'Total Games Billed',
                    '$currency${analyticsData.revenueOverview.totalGameBilled.toStringAsFixed(0)}',
                    'Revenue from completed table sessions',
                  ],
                  [
                    'Total Quick Sales Billed',
                    '$currency${analyticsData.revenueOverview.totalQuickSaleBilled.toStringAsFixed(0)}',
                    'Revenue from drinks, snacks, and retail items',
                  ],
                  [
                    'Gross Revenue',
                    '$currency${totalBilled.toStringAsFixed(0)}',
                    'Total sales before expense deduction',
                  ],
                  [
                    'Total Operating Expenses',
                    '- $currency${totalExpenses.toStringAsFixed(0)}',
                    'Supplies, repairs, utilities, and club expenses',
                  ],
                  [
                    'NET EARNINGS / PROFIT',
                    '$currency${netEarnings.toStringAsFixed(0)}',
                    'Actual club earnings (Gross Billed - Expenses)',
                  ],
                  [
                    'Cash Collected',
                    '$currency${cashCollected.toStringAsFixed(0)}',
                    'Cash paid directly at counter register',
                  ],
                  [
                    'UPI / Online Collected',
                    '$currency${upiCollected.toStringAsFixed(0)}',
                    'Digital QR / UPI settlements',
                  ],
                  [
                    'Credit Created',
                    '$currency${creditCreated.toStringAsFixed(0)}',
                    'Receivables added to player accounts',
                  ],
                  [
                    'Credit Collected',
                    '$currency${creditCollected.toStringAsFixed(0)}',
                    'Past debts settled during this period',
                  ],
                  [
                    'Current Outstanding Credit',
                    '$currency${outstandingCredit.toStringAsFixed(0)}',
                    'Total unpaid player balances club-wide',
                  ],
                ],
              ),
              pw.SizedBox(height: 18),

              // Floor-by-Floor Breakdown
              if (selectedFloorId == null && hasFloors && floors.length > 1) ...[
                pw.Text(
                  'Floor-by-Floor Performance Breakdown',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  context: ctx,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF334155),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  data: <List<String>>[
                    ['Floor Name', 'Games', 'Game Rev', 'Quick Sales', 'Expenses', 'Net Earnings'],
                    ...floors.map((f) {
                      final fGames = allGames.where((g) => g.floorId == f.id);
                      final fSales = allQuickSales.where((q) => q.floorId == f.id);
                      final fExpenses = allExpenses.where((e) => e.floorId == f.id);

                      final gRev = fGames.fold<double>(0.0, (s, g) => s + (g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0));
                      final sRev = fSales.fold<double>(0.0, (s, q) => s + q.totalAmount);
                      final eTotal = fExpenses.fold<double>(0.0, (s, e) => s + e.amount);
                      final fNet = (gRev + sRev) - eTotal;

                      return [
                        f.name,
                        fGames.length.toString(),
                        '$currency${gRev.toStringAsFixed(0)}',
                        '$currency${sRev.toStringAsFixed(0)}',
                        '$currency${eTotal.toStringAsFixed(0)}',
                        '$currency${fNet.toStringAsFixed(0)}',
                      ];
                    }),
                  ],
                ),
              ],
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'financial_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Financial Report',
          pdfBytes: bytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. GAME PERFORMANCE REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportGamePerformancePdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final selectedFloorId = ref.read(selectedFloorIdProvider);
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final allGames =
          ref.read(analyticsGamesStreamProvider).value ?? <GameSession>[];

      final games = (selectedFloorId == null
              ? allGames
              : allGames.where((g) => g.floorId == selectedFloorId).toList())
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

      final theme = await _getPdfTheme();
      final pdf = pw.Document();

      final totalGames = games.length;
      final totalPlaytimeMinutes =
          games.fold<int>(0, (s, g) => s + (g.activeSeconds ~/ 60));
      final totalGameRevenue = games.fold<double>(
        0.0,
        (s, g) => s + (g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0),
      );
      final avgMinutes =
          totalGames > 0 ? (totalPlaytimeMinutes / totalGames).round() : 0;

      // Group games by table
      final tableStats = <String, (int count, int minutes, double billing)>{};
      for (final g in games) {
        final existing = tableStats[g.tableName] ?? (0, 0, 0.0);
        final bill = g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0;
        tableStats[g.tableName] = (
          existing.$1 + 1,
          existing.$2 + (g.activeSeconds ~/ 60),
          existing.$3 + bill,
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Game Performance & Table Playtime Report',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Sessions: $totalGames',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 14),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfKpi(
                      label: 'Total Sessions',
                      value: totalGames.toString(),
                      color: const PdfColor.fromInt(0xFF0284C7),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Total Hours',
                      value: '${(totalPlaytimeMinutes / 60).toStringAsFixed(1)} hrs',
                      color: const PdfColor.fromInt(0xFF7C3AED),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Avg Duration',
                      value: '$avgMinutes mins',
                      color: const PdfColor.fromInt(0xFF059669),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Games Revenue',
                      value: '$currency${totalGameRevenue.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFFD97706),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              pw.Text(
                'Table Utilization Summary',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                data: <List<String>>[
                  ['Table Name', 'Sessions', 'Total Playtime', 'Revenue', 'Avg Session'],
                  ...tableStats.entries.map((e) {
                    final avg = e.value.$1 > 0 ? (e.value.$2 / e.value.$1).round() : 0;
                    return [
                      e.key,
                      e.value.$1.toString(),
                      '${(e.value.$2 / 60).toStringAsFixed(1)} hrs',
                      '$currency${e.value.$3.toStringAsFixed(0)}',
                      '$avg mins',
                    ];
                  }),
                ],
              ),
              pw.SizedBox(height: 18),

              pw.Text(
                'Completed Sessions Log',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF334155),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                data: <List<String>>[
                  ['Table', 'Game Type', 'Start Time', 'Duration', 'Billed', 'Mode', 'Payment'],
                  ...games.take(50).map((g) {
                    final startStr = DateFormat('d MMM, hh:mm a').format(g.startTime);
                    final bill = g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0;
                    final paymentMode = g.paymentMethod != null ? g.paymentMethod!.displayName : 'Cash';
                    return [
                      g.tableName,
                      g.gameType.name.toUpperCase(),
                      startStr,
                      '${g.activeSeconds ~/ 60}m',
                      '$currency${bill.toStringAsFixed(0)}',
                      g.billingType.name,
                      paymentMode,
                    ];
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'game_performance_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Game Performance',
          pdfBytes: bytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. PLAYERS ACTIVITY & ACCOUNTS REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportPlayersReportPdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final allGames =
          ref.read(analyticsGamesStreamProvider).value ?? <GameSession>[];
      final repo = ref.read(creditRepositoryProvider);
      final customers = await repo.watchAllCustomers().first;

      final playerGamesCount = <String, int>{};
      final playerTotalSpent = <String, double>{};

      for (final g in allGames) {
        final bill = g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0;
        for (final p in g.allPlayers) {
          playerGamesCount[p] = (playerGamesCount[p] ?? 0) + 1;
          playerTotalSpent[p] = (playerTotalSpent[p] ?? 0.0) + (bill / (g.allPlayers.isEmpty ? 1 : g.allPlayers.length));
        }
      }

      final theme = await _getPdfTheme();
      final pdf = pw.Document();

      final sortedCustomers = List<PlayerProfile>.from(customers)
        ..sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Players Activity & Khata Ledger Report',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Players Registered: ${customers.length}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 14),

              pw.Text(
                'Players Engagement & Credit Dues',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                data: <List<String>>[
                  ['Player Name', 'Phone', 'Games Played', 'Est. Spent', 'Khata Due', 'Status'],
                  ...sortedCustomers.take(50).map((c) {
                    final games = playerGamesCount[c.name] ?? 0;
                    final spent = playerTotalSpent[c.name] ?? 0.0;
                    final due = c.outstandingAmount;
                    final status = due > 0 ? 'Due ($currency${due.toStringAsFixed(0)})' : 'Clear';

                    return [
                      c.name,
                      c.mobileNumber ?? 'N/A',
                      games.toString(),
                      '$currency${spent.toStringAsFixed(0)}',
                      '$currency${due.toStringAsFixed(0)}',
                      status,
                    ];
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'players_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Players Report',
          pdfBytes: bytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. CLUB OPERATING EXPENSES REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportExpensesReportPdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final selectedFloorId = ref.read(selectedFloorIdProvider);
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final allExpenses =
          ref.read(analyticsExpensesStreamProvider).value ?? <Expense>[];

      final expenses = (selectedFloorId == null
              ? allExpenses
              : allExpenses.where((e) => e.floorId == selectedFloorId).toList())
          ..sort((a, b) => b.date.compareTo(a.date));

      final totalExpense = expenses.fold<double>(0.0, (s, e) => s + e.amount);
      final cashExpense = expenses
          .where((e) =>
              e.paymentMethod == PaymentMethod.cash ||
              (e.isCredit && e.isSettled && e.settledPaymentMethod == PaymentMethod.cash))
          .fold<double>(0.0, (s, e) => s + e.amount);
      final upiExpense = expenses
          .where((e) =>
              e.paymentMethod == PaymentMethod.upi ||
              (e.isCredit && e.isSettled && e.settledPaymentMethod == PaymentMethod.upi))
          .fold<double>(0.0, (s, e) => s + e.amount);
      final creditExpense = expenses
          .where((e) => e.isCredit && !e.isSettled)
          .fold<double>(0.0, (s, e) => s + e.amount);

      final categoryAmounts = <String, double>{};
      final categoryCounts = <String, int>{};
      for (final e in expenses) {
        categoryAmounts[e.category] = (categoryAmounts[e.category] ?? 0.0) + e.amount;
        categoryCounts[e.category] = (categoryCounts[e.category] ?? 0) + 1;
      }

      final theme = await _getPdfTheme();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Club Operating Expenses Audit Report',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Expenses: $currency${totalExpense.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 14),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfKpi(
                      label: 'Total Expenses',
                      value: '$currency${totalExpense.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFFE11D48),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'Cash Paid',
                      value: '$currency${cashExpense.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFF0284C7),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'UPI Paid',
                      value: '$currency${upiExpense.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFF7C3AED),
                    ),
                    pw.Container(width: 1, height: 30, color: PdfColors.grey300),
                    _buildPdfKpi(
                      label: 'On Credit',
                      value: '$currency${creditExpense.toStringAsFixed(0)}',
                      color: const PdfColor.fromInt(0xFFD97706),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              pw.Text(
                'Category Breakdown',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                data: <List<String>>[
                  ['Category', 'Count', 'Total Amount', 'Share %'],
                  ...categoryAmounts.entries.map((entry) {
                    final count = categoryCounts[entry.key] ?? 1;
                    final pct = totalExpense > 0 ? ((entry.value / totalExpense) * 100).toStringAsFixed(1) : '0';
                    return [
                      entry.key,
                      count.toString(),
                      '$currency${entry.value.toStringAsFixed(0)}',
                      '$pct%',
                    ];
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                'Itemized Expense Transactions',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E293B),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF334155),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                data: <List<String>>[
                  ['Date', 'Title', 'Category', 'Floor', 'Payment', 'Amount'],
                  ...expenses.take(40).map((e) {
                    final dateStr = DateFormat('d MMM, hh:mm a').format(e.date);
                    final paymentLabel = e.isOutstandingCredit
                        ? 'Credit (Unpaid)'
                        : e.paymentMethod.displayName;
                    final floorName = e.floorName ?? 'Main';

                    return [
                      dateStr,
                      e.title,
                      e.category,
                      floorName,
                      paymentLabel,
                      '$currency${e.amount.toStringAsFixed(0)}',
                    ];
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'expenses_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Expenses Report',
          pdfBytes: bytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. DUE CREDIT REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportDueCreditToPdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final repo = ref.read(creditRepositoryProvider);
      final customers = await repo.watchAllCustomers().first;

      final dueCustomers = customers
          .where((c) => c.outstandingAmount > 0)
          .toList()
        ..sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

      final theme = await _getPdfTheme();
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final List<List<String>> tableData = [
        ['Player Name', 'Mobile', 'Total Games', 'Total Paid', 'Outstanding Due'],
      ];

      for (final customer in dueCustomers) {
        final txs = await repo.watchAllTransactions(customer.id).first;
        final payments = await repo.watchPaymentHistory(customer.id).first;

        final gamesPlayed = txs.where((t) => t.type == CreditTransactionType.game).length;
        final totalPaid = payments.fold<double>(0.0, (acc, p) => acc + p.amountPaid);

        tableData.add([
          customer.name,
          customer.mobileNumber ?? 'N/A',
          gamesPlayed.toString(),
          '$currency${totalPaid.toStringAsFixed(0)}',
          '$currency${customer.outstandingAmount.toStringAsFixed(0)}',
        ]);
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Outstanding Due Credit Report',
                        style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Outstanding Players: ${dueCustomers.length}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 16),

              pw.TableHelper.fromTextArray(
                context: ctx,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E293B),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                cellAlignment: pw.Alignment.centerLeft,
                data: tableData,
              ),
            ];
          },
        ),
      );

      final fileBytes = await pdf.save();
      final fileName = 'outstanding_credit_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Due Credit Report',
          pdfBytes: fileBytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5B. EMPLOYEE DETAILS & PERFORMANCE REPORT (PDF)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportStaffPerformancePdf(
    BuildContext context,
    WidgetRef ref, {
    StaffMember? selectedStaffMember,
  }) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider).symbol;
      final range = ref.read(analyticsTimeRangeProvider);
      final selectedFloorId = ref.read(selectedFloorIdProvider);
      final floors = ref.read(floorsProvider).value ?? <FloorModel>[];
      final clubName =
          ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';

      final allMembers =
          ref.read(teamMembersStreamProvider).value ?? <StaffMember>[];
      final allGames =
          ref.read(analyticsGamesStreamProvider).value ?? <GameSession>[];
      final allQuickSales =
          ref.read(analyticsQuickSalesStreamProvider).value ?? <QuickSale>[];

      // Fetch all attendance logs from Firestore (with graceful fallback)
      List<AttendanceLog> allAttendance = [];
      try {
        final clubId = ref.read(clubIdProvider);
        if (clubId != null) {
          final snap = await FirebaseFirestore.instance
              .collection(FirebaseConstants.clubsCollection)
              .doc(clubId)
              .collection(FirebaseConstants.attendanceCollection)
              .get();
          allAttendance = snap.docs
              .map((d) => AttendanceLog.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}

      // Filter games by date range & floor
      final rangeGames = allGames.where((g) {
        final matchDate = g.startTime
                .isAfter(range.start.subtract(const Duration(seconds: 1))) &&
            g.startTime.isBefore(range.end.add(const Duration(seconds: 1)));
        final matchFloor =
            selectedFloorId == null || g.floorId == selectedFloorId;
        return matchDate && matchFloor;
      }).toList();

      // Filter quick sales by date range & floor
      final rangeQuickSales = allQuickSales.where((q) {
        final matchDate = q.date
                .isAfter(range.start.subtract(const Duration(seconds: 1))) &&
            q.date.isBefore(range.end.add(const Duration(seconds: 1)));
        final matchFloor =
            selectedFloorId == null || q.floorId == selectedFloorId;
        return matchDate && matchFloor;
      }).toList();

      // Determine which staff members to process
      final staffToProcess = selectedStaffMember != null
          ? [selectedStaffMember]
          : List<StaffMember>.from(allMembers);

      if (staffToProcess.isEmpty) {
        throw Exception('No staff members available to generate report.');
      }

      // Calculate performance metrics per employee
      final List<StaffPerformanceStats> statsList = staffToProcess.map((staff) {
        return calculateStaffStats(
          staff: staff,
          attendanceLogs: allAttendance,
          games: rangeGames,
          quickSales: rangeQuickSales,
          startDate: range.start,
          endDate: range.end,
        );
      }).toList();

      final theme = await _getPdfTheme();
      final pdf = pw.Document();

      final dateRangeStr =
          '${DateFormat("dd MMM yyyy").format(range.start)} - ${DateFormat("dd MMM yyyy").format(range.end)}';
      String floorScopeStr = 'All Floors';
      if (selectedFloorId != null) {
        final fMatch = floors.where((f) => f.id == selectedFloorId);
        if (fMatch.isNotEmpty) floorScopeStr = fMatch.first.name;
      }
      final employeeScopeStr = selectedStaffMember != null
          ? '${selectedStaffMember.name} (${selectedStaffMember.role.name.toUpperCase()})'
          : 'All Employees (${statsList.length} Staff Members)';

      // ─── Document Building ───
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clubName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      pw.Text(
                        'Employee Details & Performance Audit',
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Scope: $floorScopeStr • Target: $employeeScopeStr',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Period: $dateRangeStr',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 12),

              // If "All Employees" selected: render Consolidated Roster Table first
              if (selectedStaffMember == null) ...[
                pw.Text(
                  'Staff Roster Performance Overview',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  context: ctx,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8.5,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  data: <List<String>>[
                    [
                      'Employee',
                      'Role',
                      'Access',
                      'Shifts',
                      'Hours',
                      'Games',
                      'Game Rev',
                      'Q.Sales',
                      'QS Rev',
                      'Credit Given',
                      'Total Rev',
                    ],
                    ...statsList.map((s) {
                      return [
                        s.staff.name,
                        s.staff.role.name.toUpperCase(),
                        s.staff.isLimitedAccess ? 'Limited' : 'Full',
                        s.shiftsCount.toString(),
                        s.totalHoursWorked.toStringAsFixed(1),
                        s.gamesStartedCount.toString(),
                        '$currency${s.totalGameBilling.toStringAsFixed(0)}',
                        s.quickSalesCount.toString(),
                        '$currency${s.totalQuickSalesRevenue.toStringAsFixed(0)}',
                        '$currency${s.totalCreditGiven.toStringAsFixed(0)}',
                        '$currency${s.totalRevenueGenerated.toStringAsFixed(0)}',
                      ];
                    }),
                    // Totals Row
                    [
                      'TOTALS',
                      '-',
                      '-',
                      statsList
                          .fold<int>(0, (acc, s) => acc + s.shiftsCount)
                          .toString(),
                      statsList
                          .fold<double>(
                              0.0, (acc, s) => acc + s.totalHoursWorked)
                          .toStringAsFixed(1),
                      statsList
                          .fold<int>(0, (acc, s) => acc + s.gamesStartedCount)
                          .toString(),
                      '$currency${statsList.fold<double>(0.0, (acc, s) => acc + s.totalGameBilling).toStringAsFixed(0)}',
                      statsList
                          .fold<int>(0, (acc, s) => acc + s.quickSalesCount)
                          .toString(),
                      '$currency${statsList.fold<double>(0.0, (acc, s) => acc + s.totalQuickSalesRevenue).toStringAsFixed(0)}',
                      '$currency${statsList.fold<double>(0.0, (acc, s) => acc + s.totalCreditGiven).toStringAsFixed(0)}',
                      '$currency${statsList.fold<double>(0.0, (acc, s) => acc + s.totalRevenueGenerated).toStringAsFixed(0)}',
                    ],
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // Separated Individual Sections for Each Employee
              ...statsList.map((stats) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF334155),
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${stats.staff.name}  •  ${stats.staff.role.name.toUpperCase()}  [${stats.staff.isLimitedAccess ? "LIMITED ACCESS" : "FULL ACCESS"}]',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            stats.staff.email,
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // 4 Core KPI Cards
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFCBD5E1),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildPdfKpi(
                            label: 'Attendance & Shifts',
                            value:
                                '${stats.shiftsCount} Shifts (${stats.totalHoursWorked.toStringAsFixed(1)} hrs)',
                            color: const PdfColor.fromInt(0xFF059669),
                          ),
                          pw.Container(
                            width: 1,
                            height: 28,
                            color: PdfColors.grey300,
                          ),
                          _buildPdfKpi(
                            label: 'Games Started',
                            value:
                                '${stats.gamesStartedCount} ($currency${stats.totalGameBilling.toStringAsFixed(0)})',
                            color: const PdfColor.fromInt(0xFF0284C7),
                          ),
                          pw.Container(
                            width: 1,
                            height: 28,
                            color: PdfColors.grey300,
                          ),
                          _buildPdfKpi(
                            label: 'Quick Sales Done',
                            value:
                                '${stats.quickSalesCount} ($currency${stats.totalQuickSalesRevenue.toStringAsFixed(0)})',
                            color: const PdfColor.fromInt(0xFF7C3AED),
                          ),
                          pw.Container(
                            width: 1,
                            height: 28,
                            color: PdfColors.grey300,
                          ),
                          _buildPdfKpi(
                            label: 'Credit Given (Khata)',
                            value:
                                '$currency${stats.totalCreditGiven.toStringAsFixed(0)}',
                            color: stats.totalCreditGiven > 0
                                ? const PdfColor.fromInt(0xFFD97706)
                                : PdfColors.grey700,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // Games Started Detail Table
                    pw.Text(
                      'Games Started & Managed (${stats.games.length})',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1E293B),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (stats.games.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          'No games started by this employee in selected period.',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                      )
                    else
                      pw.TableHelper.fromTextArray(
                        context: ctx,
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF475569),
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 7.5),
                        cellPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        data: <List<String>>[
                          [
                            'Table',
                            'Game Type',
                            'Start Time',
                            'Duration',
                            'Billing',
                            'Payment Mode',
                            'Credit Given',
                          ],
                          ...stats.games.take(15).map((g) {
                            final startStr = DateFormat('d MMM, hh:mm a')
                                .format(g.startTime);
                            final bill = g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0;
                            final paymentMode = g.paymentMethod != null
                                ? g.paymentMethod!.displayName
                                : 'Pending';
                            final credit =
                                g.paymentMethod == PaymentMethod.credit
                                    ? bill
                                    : (g.remainingAmount ?? 0.0);
                            return [
                              g.tableName,
                              g.gameType.name.toUpperCase(),
                              startStr,
                              '${g.activeSeconds ~/ 60}m',
                              '$currency${bill.toStringAsFixed(0)}',
                              paymentMode,
                              credit > 0
                                  ? '$currency${credit.toStringAsFixed(0)}'
                                  : '-',
                            ];
                          }),
                        ],
                      ),
                    pw.SizedBox(height: 10),

                    // Quick Sales Detail Table
                    pw.Text(
                      'Quick Sales & Retail Deals (${stats.quickSales.length})',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1E293B),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (stats.quickSales.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          'No quick sales recorded by this employee in selected period.',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                      )
                    else
                      pw.TableHelper.fromTextArray(
                        context: ctx,
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF475569),
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 7.5),
                        cellPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        data: <List<String>>[
                          [
                            'Sale ID',
                            'Date & Time',
                            'Items Sold',
                            'Total Amount',
                            'Payment Mode',
                            'Credit Given',
                          ],
                          ...stats.quickSales.take(15).map((q) {
                            final dateStr =
                                DateFormat('d MMM, hh:mm a').format(q.date);
                            final itemsSummary = q.items
                                .map((i) => '${i.quantity}x ${i.productName}')
                                .join(', ');
                            final credit =
                                q.paymentMethod == PaymentMethod.credit
                                    ? q.totalAmount
                                    : (q.remainingAmount ?? 0.0);
                            return [
                              q.id.length > 8 ? q.id.substring(0, 8) : q.id,
                              dateStr,
                              itemsSummary.length > 30
                                  ? '${itemsSummary.substring(0, 30)}...'
                                  : itemsSummary,
                              '$currency${q.totalAmount.toStringAsFixed(0)}',
                              q.paymentMethod.displayName,
                              credit > 0
                                  ? '$currency${credit.toStringAsFixed(0)}'
                                  : '-',
                            ];
                          }),
                        ],
                      ),
                    pw.SizedBox(height: 10),

                    // Attendance Shifts Detail Table
                    pw.Text(
                      'Attendance Shifts Log (${stats.shifts.length})',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1E293B),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (stats.shifts.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          'No attendance logs recorded for this period.',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                      )
                    else
                      pw.TableHelper.fromTextArray(
                        context: ctx,
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF475569),
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 7.5),
                        cellPadding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        data: <List<String>>[
                          [
                            'Shift Date',
                            'Check-In Time',
                            'Check-Out Time',
                            'Shift Duration',
                            'Status',
                          ],
                          ...stats.shifts.take(15).map((s) {
                            final inStr = DateFormat('d MMM, hh:mm a')
                                .format(s.checkInTime);
                            final outStr = s.checkOutTime != null
                                ? DateFormat('d MMM, hh:mm a')
                                    .format(s.checkOutTime!)
                                : 'Active (Open)';
                            final duration = s.checkOutTime != null
                                ? '${(s.checkOutTime!.difference(s.checkInTime).inMinutes / 60.0).toStringAsFixed(1)} hrs'
                                : 'Ongoing';
                            final status = s.autoCheckedOut
                                ? 'Auto-Closed'
                                : s.checkOutTime != null
                                    ? 'Completed'
                                    : 'On Shift';
                            return [
                              s.dateString,
                              inStr,
                              outStr,
                              duration,
                              status,
                            ];
                          }),
                        ],
                      ),
                    pw.SizedBox(height: 24),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                    pw.SizedBox(height: 16),
                  ],
                );
              }),
            ];
          },
        ),
      );

      final fileBytes = await pdf.save();
      final safeStaffName = selectedStaffMember != null
          ? selectedStaffMember.name.replaceAll(' ', '_')
          : 'all_staff';
      final fileName =
          'employee_report_${safeStaffName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (context.mounted) {
        _hideLoading(context);
        _openPdfViewer(
          context,
          title: '$clubName Employee Details',
          pdfBytes: fileBytes,
          fileName: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Staff Performance Calculation Helper ─────────────────────────────────
  @visibleForTesting
  static StaffPerformanceStats calculateStaffStats({
    required StaffMember staff,
    required List<AttendanceLog> attendanceLogs,
    required List<GameSession> games,
    required List<QuickSale> quickSales,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // 1. Attendance
    final staffAttendance = attendanceLogs.where((a) {
      final matchesId = a.staffId.isNotEmpty && a.staffId == staff.id;
      final matchesName = a.staffName.isNotEmpty &&
          a.staffName.trim().toLowerCase() == staff.name.trim().toLowerCase();
      if (!matchesId && !matchesName) return false;
      return a.checkInTime
              .isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          a.checkInTime.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    staffAttendance.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    double totalHours = 0.0;
    for (final s in staffAttendance) {
      final out =
          s.checkOutTime ?? s.checkInTime.add(const Duration(hours: 8));
      totalHours += out.difference(s.checkInTime).inMinutes / 60.0;
    }

    // 2. Games
    final staffGames = games.where((g) {
      final matchesId =
          g.createdByUserId != null && g.createdByUserId == staff.id;
      final matchesName = g.createdByName != null &&
          g.createdByName!.trim().toLowerCase() ==
              staff.name.trim().toLowerCase();
      return matchesId || matchesName;
    }).toList();

    staffGames.sort((a, b) => b.startTime.compareTo(a.startTime));

    double gameBilling = 0.0;
    int gameMinutes = 0;
    double gameCredit = 0.0;

    for (final g in staffGames) {
      final billed = g.finalAmount ?? g.grandTotal ?? g.gameCharge ?? 0.0;
      gameBilling += billed;
      gameMinutes += (g.activeSeconds ~/ 60);

      if (g.paymentMethod == PaymentMethod.credit) {
        gameCredit += billed;
      } else if (g.remainingAmount != null && g.remainingAmount! > 0) {
        gameCredit += g.remainingAmount!;
      }
    }

    // 3. Quick Sales
    final staffQuickSales = quickSales.where((q) {
      final matchesId =
          q.createdByUserId != null && q.createdByUserId == staff.id;
      final matchesName = q.employeeName.trim().toLowerCase() ==
              staff.name.trim().toLowerCase() ||
          (q.createdByName != null &&
              q.createdByName!.trim().toLowerCase() ==
                  staff.name.trim().toLowerCase());
      return matchesId || matchesName;
    }).toList();

    staffQuickSales.sort((a, b) => b.date.compareTo(a.date));

    double qsRevenue = 0.0;
    int qsItems = 0;
    double qsCredit = 0.0;

    for (final q in staffQuickSales) {
      qsRevenue += q.totalAmount;
      for (final item in q.items) {
        qsItems += item.quantity;
      }
      if (q.paymentMethod == PaymentMethod.credit) {
        qsCredit += q.totalAmount;
      } else if (q.remainingAmount != null && q.remainingAmount! > 0) {
        qsCredit += q.remainingAmount!;
      }
    }

    return StaffPerformanceStats(
      staff: staff,
      shiftsCount: staffAttendance.length,
      totalHoursWorked: totalHours,
      shifts: staffAttendance,
      gamesStartedCount: staffGames.length,
      totalGameBilling: gameBilling,
      totalGameMinutes: gameMinutes,
      games: staffGames,
      quickSalesCount: staffQuickSales.length,
      totalQuickSalesRevenue: qsRevenue,
      quickSalesItemsCount: qsItems,
      quickSales: staffQuickSales,
      totalCreditGiven: gameCredit + qsCredit,
      totalRevenueGenerated: gameBilling + qsRevenue,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. EXCEL WORKBOOK EXPORT (Comprehensive Multi-Tab)
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportToExcel(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final analyticsData = getCompleteAnalyticsData(ref);
      final selectedFloorId = ref.read(selectedFloorIdProvider);
      final floors = ref.read(floorsProvider).value ?? <FloorModel>[];

      final gamesAsync = ref.read(analyticsGamesStreamProvider);
      final games = gamesAsync.value ?? [];

      var excel = Excel.createExcel();

      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      final s1 = excel['Financial Summary'];
      s1.appendRow([TextCellValue('Metric'), TextCellValue('Amount')]);
      s1.appendRow([
        TextCellValue('Total Billed'),
        DoubleCellValue(analyticsData.revenueOverview.totalBilled),
      ]);
      s1.appendRow([
        TextCellValue('Cash Collected'),
        DoubleCellValue(analyticsData.revenueOverview.cashCollected),
      ]);
      s1.appendRow([
        TextCellValue('UPI Collected'),
        DoubleCellValue(analyticsData.revenueOverview.upiCollected),
      ]);
      s1.appendRow([
        TextCellValue('Credit Created'),
        DoubleCellValue(analyticsData.revenueOverview.creditCreated),
      ]);
      s1.appendRow([
        TextCellValue('Outstanding Credit'),
        DoubleCellValue(analyticsData.revenueOverview.outstandingCredit),
      ]);

      final s2 = excel['Completed Games'];
      s2.appendRow([
        TextCellValue('Session ID'),
        TextCellValue('Table'),
        TextCellValue('Type'),
        TextCellValue('Floor'),
        TextCellValue('Players'),
        TextCellValue('Start Time'),
        TextCellValue('End Time'),
        TextCellValue('Duration (mins)'),
        TextCellValue('Billed Amount'),
        TextCellValue('Status'),
      ]);

      final filteredGames = selectedFloorId == null
          ? games
          : games.where((g) => g.floorId == selectedFloorId).toList();

      for (var g in filteredGames) {
        final floorName = floors
            .where((f) => f.id == g.floorId)
            .map((f) => f.name)
            .firstOrNull ?? 'Main Floor';
        s2.appendRow([
          TextCellValue(g.id),
          TextCellValue(g.tableName),
          TextCellValue(g.gameType.name),
          TextCellValue(floorName),
          TextCellValue(g.players.join(', ')),
          TextCellValue(g.startTime.toIso8601String()),
          TextCellValue(g.endTime?.toIso8601String() ?? 'N/A'),
          IntCellValue(g.endTime != null ? g.endTime!.difference(g.startTime).inMinutes : 0),
          DoubleCellValue(g.finalAmount ?? g.grandTotal ?? 0.0),
          TextCellValue(g.status.name),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final fileName = 'snooker_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final xfile = XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: fileName,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );

        if (context.mounted) {
          _hideLoading(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel Export Generated Successfully')),
          );
          final clubName =
              ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';
          Share.shareXFiles([xfile], text: '$clubName Financial Excel Export');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. CSV DATA EXPORT
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> exportToCsv(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final gamesAsync = ref.read(analyticsGamesStreamProvider);
      final games = gamesAsync.value ?? [];
      final selectedFloorId = ref.read(selectedFloorIdProvider);

      final filteredGames = selectedFloorId == null
          ? games
          : games.where((g) => g.floorId == selectedFloorId).toList();

      List<List<dynamic>> rows = [];
      rows.add([
        'Session ID',
        'Table',
        'Type',
        'Players',
        'Start Time',
        'End Time',
        'Duration (mins)',
        'Final Amount',
        'Status',
      ]);

      for (var g in filteredGames) {
        rows.add([
          g.id,
          g.tableName,
          g.gameType.name,
          g.players.join('; '),
          g.startTime.toIso8601String(),
          g.endTime?.toIso8601String() ?? '',
          (g.endTime != null ? g.endTime!.difference(g.startTime).inMinutes : 0),
          (g.finalAmount ?? g.grandTotal ?? 0.0),
          g.status.name,
        ]);
      }

      String csvData = rows.map((row) {
        return row.map((field) {
          String s = field.toString();
          if (s.contains(',') || s.contains('"') || s.contains('\n')) {
            s = s.replaceAll('"', '""');
            return '"$s"';
          }
          return s;
        }).join(',');
      }).join('\n');

      final bytes = utf8.encode(csvData);
      final fileName = 'snooker_games_${DateTime.now().millisecondsSinceEpoch}.csv';
      final xfile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: 'text/csv',
      );

      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV Generated Successfully')),
        );
        final clubName =
            ref.read(clubProfileProvider).value?.clubName ?? 'Cue Chalk';
        Share.shareXFiles([xfile], text: '$clubName Games CSV Export');
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────
  static pw.Widget _buildPdfKpi({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _hideLoading(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
