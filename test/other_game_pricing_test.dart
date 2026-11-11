import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

void main() {
  group('Other Game Category & Custom Rates Tests', () {
    const pricingSettings = PricingSettings();
    const gameSettings = GameSettings(enableOvertimeBilling: true);

    final otherTable = TableModel(
      id: 'custom_game_1',
      name: 'Air Hockey 1',
      type: TableType.other,
      customGameName: 'Air Hockey',
      allowCustomPrice: true,
      billingOptions: const {
        'oneHour': TableBillingOption(enabled: true, price: 200.0),
        'halfHour': TableBillingOption(enabled: true, price: 110.0),
        'perMinute': TableBillingOption(enabled: true, price: 4.0),
      },
    );

    test('TableModel serializes and deserializes customGameName and TableType.other', () {
      final map = otherTable.toMap();
      expect(map['type'], 'other');
      expect(map['customGameName'], 'Air Hockey');
      expect(map['allowCustomPrice'], isTrue);

      final fromMap = TableModel.fromMap(map);
      expect(fromMap.type, TableType.other);
      expect(fromMap.customGameName, 'Air Hockey');
      expect(fromMap.allowCustomPrice, isTrue);
      expect(fromMap.billingOptions?['oneHour']?.price, 200.0);
      expect(fromMap.billingOptions?['halfHour']?.price, 110.0);
      expect(fromMap.billingOptions?['perMinute']?.price, 4.0);
    });

    test('Supported billing types for Other game include halfHour, oneHour, perMinute, and customMinute', () {
      final supported = TablePricingConfig.supportedBillingTypes(otherTable, GameType.standard);
      expect(supported.contains(BillingType.oneHour), isTrue);
      expect(supported.contains(BillingType.halfHour), isTrue);
      expect(supported.contains(BillingType.perMinute), isTrue);
      expect(supported.contains(BillingType.customMinute), isTrue);
    });

    test('One Hour package within 60 mins charges base rate with 0 overtime', () {
      final charge = TablePricingConfig.calculateCharge(
        table: otherTable,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 50 * 60, // 50 mins
        framesPlayed: 0,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
        isOvertimeEnabled: true,
      );

      expect(charge.baseCharge, 200.0);
      expect(charge.overtimeMinutes, 0);
      expect(charge.overtimeCharge, 0.0);
      expect(charge.totalCharge, 200.0);
    });

    test('One Hour package with 15 mins overtime charges base rate + (15m * ₹4/min)', () {
      final charge = TablePricingConfig.calculateCharge(
        table: otherTable,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 75 * 60, // 75 mins (15 mins overtime)
        framesPlayed: 0,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
        isOvertimeEnabled: true,
      );

      expect(charge.baseCharge, 200.0);
      expect(charge.overtimeMinutes, 15);
      // 15 mins * 4.0/min = 60.0 -> total 260.0
      expect(charge.overtimeCharge, 60.0);
      expect(charge.totalCharge, 260.0);
    });

    test('Half Hour package with 10 mins overtime charges base rate + (10m * ₹4/min)', () {
      final charge = TablePricingConfig.calculateCharge(
        table: otherTable,
        gameType: GameType.standard,
        billingType: BillingType.halfHour,
        activeSeconds: 40 * 60, // 40 mins (10 mins overtime)
        framesPlayed: 0,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
        isOvertimeEnabled: true,
      );

      expect(charge.baseCharge, 110.0);
      expect(charge.overtimeMinutes, 10);
      // 10 mins * 4.0/min = 40.0 -> total 150.0
      expect(charge.overtimeCharge, 40.0);
      expect(charge.totalCharge, 150.0);
    });

    test('Custom price overrides default package price', () {
      final charge = TablePricingConfig.calculateCharge(
        table: otherTable,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 45 * 60,
        framesPlayed: 0,
        customPrice: 250.0,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
      );

      expect(charge.baseCharge, 250.0);
      expect(charge.totalCharge, 250.0);
    });

    test('Custom Minute game with perMinute rate (₹4.50/m) charges ₹70 for 15 mins (not ₹0)', () {
      final customRateTable = TableModel(
        id: 'table_custom_minute',
        name: 'Game 1',
        type: TableType.other,
        billingOptions: const {
          'perMinute': TableBillingOption(enabled: true, price: 4.5),
        },
      );

      // Even if customPrice is passed as 4.5 (per minute rate)
      final charge = TablePricingConfig.calculateCharge(
        table: customRateTable,
        gameType: GameType.standard,
        billingType: BillingType.customMinute,
        activeSeconds: 15 * 60,
        framesPlayed: 0,
        customMinutes: 15,
        customPrice: 4.5,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
      );

      // 15 * 4.5 = 67.5 -> rounded to nearest 5 is 70.0
      expect(charge.baseCharge, 70.0);
      expect(charge.totalCharge, 70.0);
    });

    test('Pool table with perFrame option calculates frame charge', () {
      final poolTable = TableModel(
        id: 'pool_1',
        name: 'Pool 1',
        type: TableType.indianPool,
        billingOptions: const {
          'perFrame': TableBillingOption(enabled: true, price: 45.0),
          'oneHour': TableBillingOption(enabled: true, price: 200.0),
          'halfHour': TableBillingOption(enabled: true, price: 100.0),
          'perMinute': TableBillingOption(enabled: true, price: 3.5),
        },
      );

      final charge = TablePricingConfig.calculateCharge(
        table: poolTable,
        gameType: GameType.standard,
        billingType: BillingType.perFrame,
        activeSeconds: 10 * 60,
        framesPlayed: 3,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
      );

      // 3 frames * 45.0 = 135.0
      expect(charge.baseCharge, 135.0);
    });

    test('Arcade table with perCoin calculates total coin tokens charge', () {
      final arcadeTable = TableModel(
        id: 'arcade_1',
        name: 'Arcade Tekken',
        type: TableType.arcade,
        billingOptions: const {
          'perCoin': TableBillingOption(enabled: true, price: 25.0),
        },
      );

      final charge = TablePricingConfig.calculateCharge(
        table: arcadeTable,
        gameType: GameType.standard,
        billingType: BillingType.perCoin,
        activeSeconds: 5 * 60,
        framesPlayed: 0,
        coinQuantity: 4,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
      );

      // 4 coins * 25.0 = 100.0
      expect(charge.baseCharge, 100.0);
      expect(charge.totalCharge, 100.0);
    });

    test('PS5 table applies extra controller fee for 2 or more players', () {
      final ps5Table = TableModel(
        id: 'ps5_1',
        name: 'PS5 Unit 1',
        type: TableType.ps5,
        billingOptions: const {
          'oneHour': TableBillingOption(enabled: true, price: 250.0, extraCharge: 50.0),
          'halfHour': TableBillingOption(enabled: true, price: 140.0, extraCharge: 30.0),
          'perMinute': TableBillingOption(enabled: true, price: 4.5),
        },
      );

      // 1 hour with 2 players (1 extra player @ ₹50)
      final charge = TablePricingConfig.calculateCharge(
        table: ps5Table,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 55 * 60,
        framesPlayed: 0,
        playersCount: 2,
        pricingConfig: pricingSettings,
        gameConfig: gameSettings,
      );

      // Base 250 + (2-1)*50 = 300.0
      expect(charge.baseCharge, 300.0);
      expect(charge.totalCharge, 300.0);
    });
  });
}
