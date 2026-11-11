import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:snooker_club/features/reports/presentation/screens/pdf_viewer_screen.dart';

void main() {
  testWidgets('PdfViewerScreen renders zoom controls and handles zoom in, zoom out and reset', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Generate a simple test PDF
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(child: pw.Text('Test Report Content'));
        },
      ),
    );
    final pdfBytes = Uint8List.fromList(await doc.save());

    await tester.pumpWidget(
      MaterialApp(
        home: PdfViewerScreen(
          title: 'Financial Report',
          pdfBytes: pdfBytes,
          fileName: 'financial_report.pdf',
        ),
      ),
    );

    // Pump a single frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title
    expect(find.text('Financial Report'), findsOneWidget);

    // Verify Zoom Controls Pill
    expect(find.byTooltip('Zoom In'), findsWidgets);
    expect(find.byTooltip('Zoom Out'), findsWidgets);
    expect(find.byTooltip('Fit to Page'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Tap Zoom In on floating pill
    final zoomInButtons = find.byTooltip('Zoom In');
    await tester.tap(zoomInButtons.last);
    await tester.pump(const Duration(milliseconds: 50));

    // Verify zoom level increased
    expect(find.text('125%'), findsOneWidget);

    // Tap Zoom In again
    await tester.tap(zoomInButtons.last);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('156%'), findsOneWidget);

    // Tap Zoom Out
    final zoomOutButtons = find.byTooltip('Zoom Out');
    await tester.tap(zoomOutButtons.last);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('125%'), findsOneWidget);

    // Tap Fit / Reset
    await tester.tap(find.byTooltip('Fit to Page'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('100%'), findsOneWidget);
  });
}
