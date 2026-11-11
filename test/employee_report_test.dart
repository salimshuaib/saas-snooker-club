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
import 'package:snooker_club/features/team/domain/models/attendance_log.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/reports/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.initialize();
  });

  group('Employee Performance & Details Report Tests', () {
    final testStaff1 = StaffMember(
      id: 'staff-1',
      name: 'Ravi Kumar',
      email: 'ravi@gmail.com',
      role: StaffRole.staff,
      accessLevel: StaffAccessLevel.full,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    final testStaff2 = StaffMember(
      id: 'staff-2',
      name: 'Shemdi Lallu',
      email: 'lallu@gmail.com',
      role: StaffRole.staff,
      accessLevel: StaffAccessLevel.limited,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    testWidgets('ReportsScreen displays Employee Report card and opens selection sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = LocalStorageService();
      await storage.initialize();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(storage),
            hasFloorsProvider.overrideWith((ref) => false),
            currentStaffProvider.overrideWith((ref) => Stream.value(testStaff1)),
            teamMembersStreamProvider.overrideWith((ref) => Stream.value([testStaff1, testStaff2])),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Employee Report card is present
      expect(find.text('Employee Details & Performance'), findsOneWidget);
      expect(find.text('Staff Audit'), findsOneWidget);

      // Scroll and tap the card
      await tester.ensureVisible(find.text('Employee Details & Performance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Employee Details & Performance'));
      await tester.pumpAndSettle();

      // Bottom sheet should open with All Employees and individual roster options
      expect(find.text('Employee Report'), findsOneWidget);
      expect(find.text('Select an employee or export full team audit'), findsOneWidget);
      expect(find.text('All Employees (Full Team Audit)'), findsOneWidget);

      // Verify staff list in modal
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Shemdi Lallu'), findsOneWidget);
      expect(find.text('LIMITED'), findsOneWidget); // Shemdi is limited access
    });

    test('StaffPerformanceStats calculation correctly audits all employee metrics', () {
      final now = DateTime(2026, 11, 12, 10, 0);

      // 1. Attendance: 2 shifts
      final attendance = <AttendanceLog>[
        AttendanceLog(
          id: 'att-1',
          staffId: 'staff-1',
          staffName: 'Ravi Kumar',
          dateString: '2026-11-12',
          checkInTime: now.subtract(const Duration(hours: 6)),
          checkOutTime: now.subtract(const Duration(hours: 2)),
        ),
        AttendanceLog(
          id: 'att-2',
          staffId: 'staff-2', // different staff
          staffName: 'Shemdi Lallu',
          dateString: '2026-11-12',
          checkInTime: now.subtract(const Duration(hours: 3)),
        ),
      ];

      // 2. Games started: 2 games started by staff-1, one cash (₹300), one credit (₹200)
      final games = <GameSession>[
        GameSession(
          id: 'game-1',
          tableId: 't1',
          tableName: 'Table 1',
          tableType: TableType.snooker,
          gameType: GameType.standard,
          mode: GameMode.solo,
          billingType: BillingType.perMinute,
          matchType: MatchType.friendly,
          teamA: const ['Player A'],
          teamB: const [],
          playerIds: const ['p1'],
          status: TableStatus.running,
          date: '2026-11-12',
          startTime: now.subtract(const Duration(minutes: 60)),
          endTime: now,
          finalAmount: 300.0,
          paymentMethod: PaymentMethod.cash,
          createdByUserId: 'staff-1',
          createdByName: 'Ravi Kumar',
        ),
        GameSession(
          id: 'game-2',
          tableId: 't2',
          tableName: 'Table 2',
          tableType: TableType.snooker,
          gameType: GameType.standard,
          mode: GameMode.solo,
          billingType: BillingType.perMinute,
          matchType: MatchType.friendly,
          teamA: const ['Player B'],
          teamB: const [],
          playerIds: const ['p2'],
          status: TableStatus.running,
          date: '2026-11-12',
          startTime: now.subtract(const Duration(minutes: 45)),
          endTime: now,
          finalAmount: 200.0,
          paymentMethod: PaymentMethod.credit,
          createdByUserId: 'staff-1',
          createdByName: 'Ravi Kumar',
        ),
        GameSession(
          id: 'game-3',
          tableId: 't3',
          tableName: 'Table 3',
          tableType: TableType.snooker,
          gameType: GameType.standard,
          mode: GameMode.solo,
          billingType: BillingType.perMinute,
          matchType: MatchType.friendly,
          teamA: const ['Player C'],
          teamB: const [],
          playerIds: const ['p3'],
          status: TableStatus.running,
          date: '2026-11-12',
          startTime: now.subtract(const Duration(minutes: 30)),
          finalAmount: 150.0,
          createdByUserId: 'staff-2', // other staff
        ),
      ];

      // 3. Quick Sales: 1 cash (₹80), 1 credit (₹120)
      final quickSales = <QuickSale>[
        QuickSale(
          id: 'qs-1',
          items: const [
            GameOrder(
              id: 'ord-1',
              productId: 'prod-1',
              productName: 'Cold Drink',
              category: 'Beverage',
              quantity: 2,
              pricePerUnit: 40.0,
            ),
          ],
          totalAmount: 80.0,
          paymentMethod: PaymentMethod.cash,
          employeeName: 'Ravi Kumar',
          createdByUserId: 'staff-1',
          date: now.subtract(const Duration(hours: 1)),
        ),
        QuickSale(
          id: 'qs-2',
          items: const [
            GameOrder(
              id: 'ord-2',
              productId: 'prod-2',
              productName: 'Chalk Box',
              category: 'Accessories',
              quantity: 1,
              pricePerUnit: 120.0,
            ),
          ],
          totalAmount: 120.0,
          paymentMethod: PaymentMethod.credit,
          employeeName: 'Ravi Kumar',
          createdByUserId: 'staff-1',
          date: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      final stats = ExportService.calculateStaffStats(
        staff: testStaff1,
        attendanceLogs: attendance,
        games: games,
        quickSales: quickSales,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Verify Attendance
      expect(stats.shiftsCount, 1);
      expect(stats.totalHoursWorked, closeTo(4.0, 0.1));

      // Verify Games Started
      expect(stats.gamesStartedCount, 2);
      expect(stats.totalGameBilling, 500.0);

      // Verify Quick Sales
      expect(stats.quickSalesCount, 2);
      expect(stats.totalQuickSalesRevenue, 200.0);
      expect(stats.quickSalesItemsCount, 3); // 2 drinks + 1 chalk

      // Verify Credit Authorized (₹200 from game + ₹120 from quick sale = ₹320)
      expect(stats.totalCreditGiven, 320.0);

      // Verify Combined Revenue Generated (₹500 games + ₹200 quick sales = ₹700)
      expect(stats.totalRevenueGenerated, 700.0);
    });
  });
}
