// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/reports/services/export_providers.dart';

class ExportService {
  static Future<void> exportToExcel(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final range = ref.read(analyticsTimeRangeProvider);
      
      final analyticsData = ref.read(completeAnalyticsProvider);
      final gamesAsync = ref.read(analyticsGamesStreamProvider);
      final quickSalesAsync = ref.read(analyticsQuickSalesStreamProvider);
      final creditsAsync = ref.read(reportCreditsStreamProvider);

      final games = gamesAsync.value ?? [];
      final quickSales = quickSalesAsync.value ?? [];
      final credits = creditsAsync.value ?? [];

      var excel = Excel.createExcel();
      
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      final s1 = excel['Financial Summary'];
      s1.appendRow([TextCellValue('Metric'), TextCellValue('Amount')]);
      s1.appendRow([TextCellValue('Total Billed'), DoubleCellValue(analyticsData.revenueOverview.totalBilled)]);
      s1.appendRow([TextCellValue('Cash Collected'), DoubleCellValue(analyticsData.revenueOverview.cashCollected)]);
      s1.appendRow([TextCellValue('UPI Collected'), DoubleCellValue(analyticsData.revenueOverview.upiCollected)]);
      s1.appendRow([TextCellValue('Credit Created'), DoubleCellValue(analyticsData.revenueOverview.creditCreated)]);
      s1.appendRow([TextCellValue('Credit Collected'), DoubleCellValue(analyticsData.revenueOverview.creditCollected)]);
      s1.appendRow([TextCellValue('Outstanding Credit'), DoubleCellValue(analyticsData.revenueOverview.outstandingCredit)]);
      s1.appendRow([TextCellValue('')]);
      s1.appendRow([TextCellValue('Report Start Date'), TextCellValue(range.start.toIso8601String())]);
      s1.appendRow([TextCellValue('Report End Date'), TextCellValue(range.end.toIso8601String())]);
      s1.appendRow([TextCellValue('Generated At'), TextCellValue(DateTime.now().toIso8601String())]);

      final s2 = excel['Games'];
      s2.appendRow([
        TextCellValue('ID'), TextCellValue('Start Time'), TextCellValue('End Time'), 
        TextCellValue('Table ID'), TextCellValue('Duration (mins)'), TextCellValue('Amount'), 
        TextCellValue('Payment Method'), TextCellValue('Status')
      ]);
      for (var g in games) {
        final paymentMethods = g.playerPaymentMethods != null ? g.playerPaymentMethods!.values.map((e) => e.name).join(', ') : 'unknown';
        s2.appendRow([
          TextCellValue(g.id),
          TextCellValue(g.startTime.toIso8601String()),
          TextCellValue(g.endTime?.toIso8601String() ?? ''),
          TextCellValue(g.tableId),
          IntCellValue(g.endTime != null ? g.endTime!.difference(g.startTime).inMinutes : 0),
          DoubleCellValue(g.grandTotal ?? 0.0),
          TextCellValue(paymentMethods),
          TextCellValue(g.status.name),
        ]);
      }

      final s3 = excel['Quick Sales'];
      s3.appendRow([
        TextCellValue('ID'), TextCellValue('Time'), TextCellValue('Item'), 
        TextCellValue('Quantity'), TextCellValue('Total Amount'), TextCellValue('Payment Method')
      ]);
      for (var q in quickSales) {
        final paymentMethod = q.paymentMethod.name;
        s3.appendRow([
          TextCellValue(q.id),
          TextCellValue(q.date.toIso8601String()),
          TextCellValue(q.items.map((i) => i.productName).join(', ')),
          IntCellValue(q.items.fold(0, (sum, i) => sum + i.quantity)),
          DoubleCellValue(q.totalAmount),
          TextCellValue(paymentMethod),
        ]);
      }

      final s4 = excel['Credit Transactions'];
      s4.appendRow([
        TextCellValue('ID'), TextCellValue('Time'), TextCellValue('Customer ID'), 
        TextCellValue('Original Amount'), TextCellValue('Remaining Amount'), TextCellValue('Status')
      ]);
      for (var c in credits) {
        s4.appendRow([
          TextCellValue(c.id),
          TextCellValue(c.date.toIso8601String()),
          TextCellValue(c.customerId),
          DoubleCellValue(c.amount),
          DoubleCellValue(c.remainingAmount),
          TextCellValue(c.status.name),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final xfile = XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: 'snooker_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        
        if (context.mounted) {
          _hideLoading(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Generated Successfully')));
          Share.shareXFiles([xfile], text: 'Sharma Billiards Financial Excel Report');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static Future<void> exportToPdf(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final currency = ref.read(currencyProvider);
      final range = ref.read(analyticsTimeRangeProvider);
      final analyticsData = ref.read(completeAnalyticsProvider);

      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (pw.Context ctx) {
          final symbol = currency.symbol;
          return [
            pw.Header(level: 0, child: pw.Text('Sharma Billiards - Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Text('Date Range: ${DateFormat("yyyy-MM-dd").format(range.start)} to ${DateFormat("yyyy-MM-dd").format(range.end)}'),
            pw.Text('Generated: ${DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            
            pw.Header(level: 1, child: pw.Text('Financial Summary')),
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: <List<String>>[
                ['Metric', 'Amount'],
                ['Total Billed', '$symbol${analyticsData.revenueOverview.totalBilled.toStringAsFixed(0)}'],
                ['Cash Collected', '$symbol${analyticsData.revenueOverview.cashCollected.toStringAsFixed(0)}'],
                ['UPI Collected', '$symbol${analyticsData.revenueOverview.upiCollected.toStringAsFixed(0)}'],
                ['Credit Created', '$symbol${analyticsData.revenueOverview.creditCreated.toStringAsFixed(0)}'],
                ['Credit Collected', '$symbol${analyticsData.revenueOverview.creditCollected.toStringAsFixed(0)}'],
                ['Outstanding Credit', '$symbol${analyticsData.revenueOverview.outstandingCredit.toStringAsFixed(0)}'],
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Game Category Performance')),
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: <List<String>>[
                ['Category', 'Games', 'Total Billed'],
                ...analyticsData.gameAnalytics.categories.map((c) => [
                  c.categoryName,
                  c.transactionCount.toString(),
                  '$symbol${c.totalBilled.toStringAsFixed(0)}'
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Top Quick Sale Products')),
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: <List<String>>[
                ['Product', 'Qty Sold', 'Total Revenue'],
                ...analyticsData.bestSellingProducts.take(15).map((p) => [
                  p.productName,
                  p.unitsSold.toString(),
                  '$symbol${p.salesAmount.toStringAsFixed(0)}'
                ]),
              ],
            ),
          ];
        },
      ));

      final bytes = await pdf.save();
      final xfile = XFile.fromData(
        bytes,
        name: 'snooker_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        mimeType: 'application/pdf',
      );

      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Generated Successfully')));
        Share.shareXFiles([xfile], text: 'Sharma Billiards Financial Report');
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static Future<void> exportToCsv(BuildContext context, WidgetRef ref) async {
    _showLoading(context);
    try {
      final gamesAsync = ref.read(analyticsGamesStreamProvider);
      final games = gamesAsync.value ?? [];

      List<List<dynamic>> rows = [
        ['ID', 'Start Time', 'End Time', 'Table ID', 'Duration (mins)', 'Amount', 'Payment Method', 'Status']
      ];

      for (var g in games) {
        final paymentMethods = g.playerPaymentMethods != null ? g.playerPaymentMethods!.values.map((e) => e.name).join(', ') : 'unknown';
        rows.add([
          g.id,
          g.startTime.toIso8601String(),
          g.endTime?.toIso8601String() ?? '',
          g.tableId,
          (g.endTime != null ? g.endTime!.difference(g.startTime).inMinutes : 0),
          (g.grandTotal ?? 0.0),
          paymentMethods,
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
      final xfile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: 'snooker_games_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
      );

      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Generated Successfully')));
        Share.shareXFiles([xfile], text: 'Sharma Billiards Games CSV Export');
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
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
