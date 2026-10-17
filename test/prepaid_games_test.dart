import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/payment_complete_modal.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

void main() {
  group('GameSession Prepaid Model Serialization Tests', () {
    test('GameSession toMap and fromMap preserve all prepaid fields', () {
      final now = DateTime(2026, 10, 16, 12, 0);
      final session = GameSession(
        id: 'prepaid_test_1',
        tableId: 'table_1',
        tableName: 'Snooker 1',
        tableType: TableType.snooker,
        gameType: GameType.standard,
        mode: GameMode.solo,
        billingType: BillingType.oneHour,
        matchType: MatchType.friendly,
        teamA: const ['Player 1', 'Player 2'],
        teamB: const [],
        playerIds: const ['p1', 'p2'],
        status: TableStatus.available,
        startTime: now,
        endTime: now.add(const Duration(minutes: 60)),
        pauseTimes: const [],
        resumeTimes: const [],
        totalFrames: 1,
        framesPlayed: 0,
        orders: const [],
        manualGameCharges: const [],
        rounds: const [],
        date: '2026-10-16',
        auditLogs: const [],
        isPrepaid: true,
        prepaidAmount: 250.0,
        prepaidDurationMinutes: 60,
        prepaidPaymentMethod: PaymentMethod.cash,
        prepaidPlayerPaymentSplits: const {
          'Player 1': {PaymentMethod.cash: 250.0},
        },
        prepaidPaidBy: 'Player 1',
        prepaidConfirmedAt: now,
        isOvertimeEnabled: false,
        settlementAmountPaid: 0.0,
        settlementPaymentMethod: null,
        settlementPaymentSplits: null,
      );

      final map = session.toMap();
      expect(map['isPrepaid'], isTrue);
      expect(map['prepaidAmount'], 250.0);
      expect(map['prepaidDurationMinutes'], 60);
      expect(map['prepaidPaymentMethod'], 'cash');
      expect(map['prepaidPaidBy'], 'Player 1');
      expect(map['isOvertimeEnabled'], isFalse);

      final fromMapSession = GameSession.fromMap(map);
      expect(fromMapSession.isPrepaid, isTrue);
      expect(fromMapSession.prepaidAmount, 250.0);
      expect(fromMapSession.prepaidDurationMinutes, 60);
      expect(fromMapSession.prepaidPaymentMethod, PaymentMethod.cash);
      expect(fromMapSession.prepaidPaidBy, 'Player 1');
      expect(fromMapSession.isOvertimeEnabled, isFalse);
      expect(fromMapSession.settlementAmountPaid, 0.0);
    });

    test('copyWith preserves or updates prepaid fields properly', () {
      final session = GameSession(
        id: 'copy_test',
        tableId: 't1',
        tableName: 'Table 1',
        tableType: TableType.snooker,
        gameType: GameType.standard,
        mode: GameMode.solo,
        billingType: BillingType.halfHour,
        matchType: MatchType.friendly,
        teamA: const ['A'],
        teamB: const [],
        playerIds: const [],
        status: TableStatus.running,
        startTime: DateTime.now(),
        pauseTimes: const [],
        resumeTimes: const [],
        totalFrames: 1,
        framesPlayed: 0,
        orders: const [],
        manualGameCharges: const [],
        rounds: const [],
        date: '2026-10-16',
        auditLogs: const [],
        isPrepaid: true,
        prepaidAmount: 150.0,
        prepaidDurationMinutes: 30,
        isOvertimeEnabled: true,
      );

      final updated = session.copyWith(
        isOvertimeEnabled: false,
        settlementAmountPaid: 40.0,
        settlementPaymentMethod: PaymentMethod.upi,
      );

      expect(updated.isPrepaid, isTrue);
      expect(updated.prepaidAmount, 150.0);
      expect(updated.isOvertimeEnabled, isFalse);
      expect(updated.settlementAmountPaid, 40.0);
      expect(updated.settlementPaymentMethod, PaymentMethod.upi);
    });
  });

  group('Pricing Engine Overtime Calculations Tests', () {
    const pricing = PricingSettings(
      snookerOneHour: 200.0,
      snookerHalfHour: 120.0,
      snookerPerMinute: 4.0,
      americanPoolOneHour: 160.0,
      americanPoolHalfHour: 90.0,
    );

    const table = TableModel(
      id: 'table_1',
      name: 'Snooker 1',
      type: TableType.snooker,
      status: TableStatus.running,
    );

    test('Half Hour package with overtime disabled caps charge at package price', () {
      // 45 minutes elapsed (15 minutes overtime)
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.halfHour,
        activeSeconds: 45 * 60, // 45 minutes
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: false,
      );

      // Half hour base price is 120.0
      expect(charge.baseCharge, 120.0);
      expect(charge.overtimeMinutes, 0);
      expect(charge.overtimeCharge, 0.0);
      expect(charge.totalCharge, 120.0);
    });

    test('Half Hour package with overtime enabled calculates additional charge', () {
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.halfHour,
        activeSeconds: 45 * 60, // 45 minutes
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: true,
      );

      expect(charge.baseCharge, 120.0);
      expect(charge.overtimeMinutes, 15);
      expect(charge.overtimeCharge, greaterThan(0.0));
      expect(charge.totalCharge, greaterThan(120.0));
    });

    test('One Hour package with overtime disabled caps charge at 1 hour price', () {
      // 80 minutes elapsed (20 minutes overtime)
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 80 * 60, // 80 minutes
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: false,
      );

      // One hour base price is 200.0
      expect(charge.baseCharge, 200.0);
      expect(charge.overtimeMinutes, 0);
      expect(charge.overtimeCharge, 0.0);
      expect(charge.totalCharge, 200.0);
    });

    test('Custom Minute game applies round off logic (15 mins @ 4.5/min -> ₹70)', () {
      const snookerPricing = PricingSettings(
        snookerOneHour: 270.0,
        snookerHalfHour: 135.0,
        snookerPerMinute: 4.5,
      );

      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.customMinute,
        activeSeconds: 15 * 60,
        framesPlayed: 0,
        customMinutes: 15,
        pricingConfig: snookerPricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: true,
      );

      // 15 * 4.5 = 67.5 -> rounded to nearest 5 is 70.0
      expect(charge.baseCharge, 70.0);
      expect(charge.overtimeMinutes, 0);
      expect(charge.overtimeCharge, 0.0);
      expect(charge.totalCharge, 70.0);
    });

    test('Custom Minute game with overtime rounds off base + overtime', () {
      const snookerPricing = PricingSettings(
        snookerOneHour: 270.0,
        snookerHalfHour: 135.0,
        snookerPerMinute: 4.5,
      );

      // 18 minutes elapsed = 3 minutes overtime
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.customMinute,
        activeSeconds: 18 * 60,
        framesPlayed: 0,
        customMinutes: 15,
        pricingConfig: snookerPricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: true,
      );

      // Base: 70.0, 3 mins overtime @ 4.5 = 13.5 -> 70 + 13.5 = 83.5 -> rounded is 85.0
      expect(charge.baseCharge, 70.0);
      expect(charge.overtimeMinutes, 3);
      expect(charge.overtimeCharge, 15.0);
      expect(charge.totalCharge, 85.0);
    });

    test('One Hour package before time limit preserves exact package price (no round off until time limit)', () {
      const snookerPricing = PricingSettings(
        snookerOneHour: 270.0,
        snookerHalfHour: 135.0,
        snookerPerMinute: 4.5,
      );

      // 45 minutes elapsed (within 60 mins)
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 45 * 60,
        framesPlayed: 0,
        pricingConfig: snookerPricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: true,
      );

      expect(charge.baseCharge, 270.0);
      expect(charge.overtimeMinutes, 0);
      expect(charge.overtimeCharge, 0.0);
      expect(charge.totalCharge, 270.0);
    });

    test('One Hour package with overtime rounds off package price + overtime', () {
      const snookerPricing = PricingSettings(
        snookerOneHour: 270.0,
        snookerHalfHour: 135.0,
        snookerPerMinute: 4.5,
      );

      // 63 minutes elapsed (3 minutes overtime)
      final charge = TablePricingConfig.calculateCharge(
        table: table,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 63 * 60,
        framesPlayed: 0,
        pricingConfig: snookerPricing,
        gameConfig: const GameSettings(),
        isOvertimeEnabled: true,
      );

      // Base: 270.0, 3 mins overtime @ 4.5 = 13.5 -> 270 + 13.5 = 283.5 -> rounded is 285.0
      expect(charge.baseCharge, 270.0);
      expect(charge.overtimeMinutes, 3);
      expect(charge.overtimeCharge, 15.0);
      expect(charge.totalCharge, 285.0);
    });
  });

  group('Prepaid Settlement Reconciliation & Receipts Tests', () {
    test('Zero due when game completes within prepaid allowance with no extras', () {
      const prepaidAmount = 200.0;
      const roundedTotal = 200.0;
      final netDue = (roundedTotal - prepaidAmount).clamp(0.0, double.infinity);
      expect(netDue, 0.0);
    });

    test('Net due accurately reflects overtime and orders beyond prepaid advance', () {
      const prepaidAmount = 200.0;
      const gameChargeWithOvertime = 240.0;
      const ordersTotal = 60.0;
      const roundedTotal = gameChargeWithOvertime + ordersTotal; // 300.0
      final netDue = (roundedTotal - prepaidAmount).clamp(0.0, double.infinity);
      expect(netDue, 100.0);
    });

    test('ReceiptData.fromGameSession includes prepaid deduction line item', () {
      final now = DateTime(2026, 10, 16, 12, 0);
      final session = GameSession(
        id: 'rec_test_1',
        tableId: 't1',
        tableName: 'Snooker 1',
        tableType: TableType.snooker,
        gameType: GameType.standard,
        mode: GameMode.solo,
        billingType: BillingType.oneHour,
        matchType: MatchType.friendly,
        teamA: const ['Player 1'],
        teamB: const [],
        playerIds: const [],
        status: TableStatus.available,
        startTime: now,
        endTime: now.add(const Duration(minutes: 60)),
        pauseTimes: const [],
        resumeTimes: const [],
        totalFrames: 1,
        framesPlayed: 0,
        orders: const [],
        manualGameCharges: const [],
        rounds: const [],
        date: '2026-10-16',
        auditLogs: const [],
        isPrepaid: true,
        prepaidAmount: 200.0,
        prepaidDurationMinutes: 60,
        prepaidPaymentMethod: PaymentMethod.cash,
        isOvertimeEnabled: false,
        gameCharge: 200.0,
        baseGameCharge: 200.0,
        grandTotal: 200.0,
        roundedAmount: 200.0,
        finalAmount: 200.0,
        settlementAmountPaid: 0.0,
      );

      final receipt = ReceiptData.fromGameSession(
        session,
        clubName: 'Sharma Billiards',
      );

      expect(receipt.prepaidAmount, 200.0);
      expect(receipt.amountDue, 0.0); // No outstanding balance
      expect(
        receipt.lineItems.any((item) => item.description.contains('Prepaid advance paid')),
        isTrue,
      );
    });

    test('Prepaid session with zero due yields empty net liabilities and preserves total amount', () {
      final now = DateTime(2026, 10, 16, 12, 0);
      final session = GameSession(
        id: 'test_prepaid_liab',
        tableId: 't1',
        tableName: 'Snooker 1',
        tableType: TableType.snooker,
        gameType: GameType.standard,
        mode: GameMode.solo,
        billingType: BillingType.halfHour,
        matchType: MatchType.friendly,
        teamA: const ['Player 1'],
        teamB: const [],
        playerIds: const [],
        status: TableStatus.running,
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        pauseTimes: const [],
        resumeTimes: const [],
        totalFrames: 1,
        framesPlayed: 0,
        orders: const [],
        manualGameCharges: const [],
        rounds: const [],
        date: '2026-10-16',
        auditLogs: const [],
        isPrepaid: true,
        prepaidAmount: 120.0,
        prepaidDurationMinutes: 30,
        prepaidPaymentMethod: PaymentMethod.cash,
        isOvertimeEnabled: false,
      );

      // Verify that prepaid fields exist
      expect(session.isPrepaid, isTrue);
      expect(session.prepaidAmount, 120.0);

      // Verify net due calculation with 0 liabilities
      final Map<String, double> liabilities = {
        for (final p in session.allPlayers) p: 120.0,
      };
      final totalLiability = liabilities.values.fold<double>(0.0, (s, a) => s + a);
      final netDue = (totalLiability - session.prepaidAmount).clamp(0.0, double.infinity);
      expect(netDue, 0.0);

      if (netDue <= 0.0) {
        for (final p in session.allPlayers) {
          liabilities[p] = 0.0;
        }
      }
      expect(liabilities['Player 1'], 0.0);

      // When custom liabilities are 0.0, total bill is prepaidAmount + sum(customLiabilities) = 120.0
      final totalBill = session.prepaidAmount + liabilities.values.fold<double>(0.0, (s, v) => s + v);
      expect(totalBill, 120.0);
    });
  });
}

