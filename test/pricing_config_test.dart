import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

void main() {
  final testPricing = PricingSettings(
    snookerHalfHour: 135,
    snookerOneHour: 270,
    snookerPerMinute: 4.5,
    indianPoolHalfHour: 100,
    indianPoolOneHour: 210,
    indianPoolPerFrame: 45,
    indianPoolPerMinute: 3.5,
    americanPoolHalfHour: 150,
    americanPoolOneHour: 240,
    americanPoolPerFrame: 70,
    americanPoolPerMinute: 4.0,
  );
  
  final testGameConfig = GameSettings(
                  );

  group('TablePricingConfig Unit Tests', () {
    test('Verify centralized prices for Snooker', () {
      expect(TablePricingConfig.getPrice(TableType.snooker, GameType.standard, BillingType.halfHour, testPricing), 135.00);
      expect(TablePricingConfig.getPrice(TableType.snooker, GameType.standard, BillingType.oneHour, testPricing), 270.00);
      expect(TablePricingConfig.getPerMinutePrice(TableType.snooker, GameType.standard, testPricing), 4.50);
    });

    test('Verify centralized prices for Indian Pool', () {
      expect(TablePricingConfig.getPrice(TableType.indianPool, GameType.standard, BillingType.halfHour, testPricing), 100.00);
      expect(TablePricingConfig.getPrice(TableType.indianPool, GameType.standard, BillingType.oneHour, testPricing), 210.00);
      expect(TablePricingConfig.getPrice(TableType.indianPool, GameType.standard, BillingType.perFrame, testPricing), 45.00);
      expect(TablePricingConfig.getPerMinutePrice(TableType.indianPool, GameType.standard, testPricing), 3.50);
    });

    test('Verify centralized prices for American Pool', () {
      expect(TablePricingConfig.getPrice(TableType.americanPool, GameType.standard, BillingType.halfHour, testPricing), 150.00);
      expect(TablePricingConfig.getPrice(TableType.americanPool, GameType.standard, BillingType.oneHour, testPricing), 240.00);
      expect(TablePricingConfig.getPrice(TableType.americanPool, GameType.standard, BillingType.perFrame, testPricing), 70.00);
      expect(TablePricingConfig.getPerMinutePrice(TableType.americanPool, GameType.standard, testPricing), 4.00);
    });

    test('Verify per-second billing calculations and exact internal precision', () {
      // Snooker: 4.50 / 60 = 0.075 per second
      expect(TablePricingConfig.getPerMinutePrice(TableType.snooker, GameType.standard, testPricing) / 60.0, 0.075);
      
      // Test exact per-second billing calculation for perMinute billing
      final perMinCharge = TablePricingConfig.calculateCharge(
        tableType: TableType.snooker,
        gameType: GameType.standard,
        billingType: BillingType.perMinute,
        activeSeconds: 100, // 100 seconds @ 0.075/sec = 7.5
        framesPlayed: 0,
        pricingConfig: testPricing,
        gameConfig: testGameConfig,
      );
      expect(perMinCharge.baseCharge, 100 * 0.075);
      expect(perMinCharge.totalCharge, 7.5);

      // Test package base charge with no overtime
      final snookerCharge = TablePricingConfig.calculateCharge(
        tableType: TableType.snooker,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 1800, // 30 minutes into a 1 hour package
        framesPlayed: 0,
        pricingConfig: testPricing,
        gameConfig: testGameConfig,
      );
      expect(snookerCharge.baseCharge, 270.00); // Package base fee
      expect(snookerCharge.overtimeCharge, 0.0);
      expect(snookerCharge.totalCharge, 270.00);

      // Snooker Overtime: 1 hour package + 10 minutes (600 seconds) overtime
      final snookerOvertime = TablePricingConfig.calculateCharge(
        tableType: TableType.snooker,
        gameType: GameType.standard,
        billingType: BillingType.oneHour,
        activeSeconds: 3600 + 600,
        framesPlayed: 0,
        pricingConfig: testPricing,
        gameConfig: testGameConfig,
      );
      expect(snookerOvertime.overtimeMinutes, 10);
      expect(snookerOvertime.overtimeCharge, 600 * 0.075); // Exactly 45.0
      expect(snookerOvertime.totalCharge, 270.00 + 45.00);
    });
  });
}
