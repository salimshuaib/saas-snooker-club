import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/services/local_storage_service.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/reports/presentation/screens/reports_screen.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

void main() {
  testWidgets('ReportsScreen renders clean report cards with info buttons and floating details sheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.initialize();

    final now = DateTime.now();
    final testStaff = StaffMember(
      id: 'staff-1',
      name: 'Owner Admin',
      email: 'owner@snooker.club',
      role: StaffRole.owner,
      accessLevel: StaffAccessLevel.full,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          currentStaffProvider.overrideWith((ref) => Stream.value(testStaff)),
          hasFloorsProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Business PDF Reports section is rendered
    expect(find.text('Business PDF Reports'), findsOneWidget);

    // Verify report titles are present without overwhelming subtitle clutter
    expect(find.text('Financial & Revenue Report'), findsOneWidget);
    expect(find.text('Game Performance & Tables'), findsOneWidget);
    expect(find.text('Players Activity & Accounts'), findsOneWidget);
    expect(find.text('Club Operating Expenses'), findsOneWidget);
    expect(find.text('Outstanding Due Credit'), findsOneWidget);
    expect(find.text('Employee Details & Performance'), findsOneWidget);

    // Verify tags are displayed cleanly
    expect(find.text('P&L Statement'), findsOneWidget);
    expect(find.text('Tables & Playtime'), findsOneWidget);
    expect(find.text('Players & Spending'), findsOneWidget);
    expect(find.text('Expenses Audit'), findsOneWidget);
    expect(find.text('Debt Recovery'), findsOneWidget);
    expect(find.text('Staff Audit'), findsOneWidget);

    // Verify old cluttered subtitles are NOT rendered in the main card list
    expect(
      find.text('Gross billing, operating expense deductions, net earnings & floor breakdown'),
      findsNothing,
    );

    // Verify "i" info buttons exist for each report and spreadsheet
    final infoButtons = find.byIcon(Icons.info_outline_rounded);
    // 6 PDF reports + 2 Spreadsheets = 8 info buttons
    expect(infoButtons, findsNWidgets(8));

    // Tap the first info button ("Financial & Revenue Report")
    await tester.tap(infoButtons.first);
    await tester.pumpAndSettle();

    // Verify floating info sheet opens with detailed report breakdown and action button
    expect(find.text('What this report includes:'), findsOneWidget);
    expect(find.text('View / Download PDF'), findsOneWidget);
    expect(find.text('Gross billing vs. operating expenses audit'), findsOneWidget);

    // Close the sheet via close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify sheet is dismissed
    expect(find.text('What this report includes:'), findsNothing);

    // Tap info button on Excel Workbook (index 6 after 6 PDF reports)
    await tester.ensureVisible(infoButtons.at(6));
    await tester.pumpAndSettle();
    await tester.tap(infoButtons.at(6));
    await tester.pumpAndSettle();

    expect(find.text('What this report includes:'), findsOneWidget);
    expect(find.text('Export & Download'), findsOneWidget);
    expect(find.text('Summary KPIs & P&L tab'), findsOneWidget);

    // Close the sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
  });
}
