import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/presentation/screens/resource_management_screen.dart';

void main() {
  group('PS5 Tiered Pricing Matrix Tests', () {
    const regularPs5 = TableModel(
      id: 'ps5_1',
      name: 'PS5 1',
      type: TableType.ps5,
      floorName: '1st Floor',
    );

    const basement4Ps5ByName = TableModel(
      id: 'ps5_12',
      name: 'PS5 12',
      type: TableType.ps5,
      floorName: 'Ground Floor',
    );

    const basement4Ps5ByFloor = TableModel(
      id: 'ps5_custom',
      name: 'Screen 5',
      type: TableType.ps5,
      floorName: 'Basement 4',
    );

    test('Basement 4 detection', () {
      expect(TablePricingConfig.isBasement4Ps5(regularPs5), isFalse);
      expect(TablePricingConfig.isBasement4Ps5(basement4Ps5ByName), isTrue);
      expect(
        TablePricingConfig.isBasement4Ps5(
          const TableModel(id: '13', name: 'PS5-13', type: TableType.ps5),
        ),
        isTrue,
      );
      expect(
        TablePricingConfig.isBasement4Ps5(
          const TableModel(id: '14', name: 'ps5 14', type: TableType.ps5),
        ),
        isTrue,
      );
      expect(
        TablePricingConfig.isBasement4Ps5(
          const TableModel(id: '15', name: 'PS5 15 Screen', type: TableType.ps5),
        ),
        isTrue,
      );
      expect(TablePricingConfig.isBasement4Ps5(basement4Ps5ByFloor), isTrue);
    });

    test('Regular PS5 1-Hour pricing (1 to 4 controllers)', () {
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHour,
        controllers: 1,
      ), 200.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHour,
        controllers: 2,
      ), 240.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHour,
        controllers: 3,
      ), 360.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHour,
        controllers: 4,
      ), 480.0);

      // 5 controllers -> +120
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHour,
        controllers: 5,
      ), 600.0);
    });

    test('Regular PS5 1.5-Hours (90 min) pricing (1 to 4 controllers)', () {
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHourThirty,
        controllers: 1,
      ), 300.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHourThirty,
        controllers: 2,
      ), 390.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHourThirty,
        controllers: 3,
      ), 570.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.oneHourThirty,
        controllers: 4,
      ), 760.0);
    });

    test('Regular PS5 30-Minutes pricing (1 to 4 controllers)', () {
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.halfHour,
        controllers: 1,
      ), 100.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.halfHour,
        controllers: 2,
      ), 150.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.halfHour,
        controllers: 3,
      ), 220.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: regularPs5,
        billingType: BillingType.halfHour,
        controllers: 4,
      ), 280.0);
    });

    test('Basement 4 special rates (single controller discount)', () {
      // 1 Hour
      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.oneHour,
        controllers: 1,
      ), 150.0); // Discounted from 200

      // 30 Minutes
      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.halfHour,
        controllers: 1,
      ), 80.0); // Discounted from 100

      // 1.5 Hours
      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.oneHourThirty,
        controllers: 1,
      ), 225.0); // Discounted from 300

      // Multi-controller rates remain identical to regular PS5
      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.oneHour,
        controllers: 2,
      ), 240.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.oneHour,
        controllers: 3,
      ), 360.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: basement4Ps5ByName,
        billingType: BillingType.oneHour,
        controllers: 4,
      ), 480.0);
    });
  });

  group('Settings & Arcade Gaming Resolution Tests', () {
    test('Default resolution based on club name or slug', () {
      const defaultSettings = GameSettings();

      // Enabled by default for "Arcade Gaming" or clubs with "arcade"
      expect(defaultSettings.isPs5ControllerPricingEnabled(clubName: 'Arcade Gaming'), isTrue);
      expect(defaultSettings.isPs5ControllerPricingEnabled(slug: 'arcade-gaming-center'), isTrue);
      expect(defaultSettings.isPs5ControllerPricingEnabled(clubName: 'Snooker & Billiards Club'), isFalse);

      // Explicit toggle overrides club name
      final disabledExplicitly = defaultSettings.copyWith(enablePs5ControllerPricing: false);
      expect(disabledExplicitly.isPs5ControllerPricingEnabled(clubName: 'Arcade Gaming'), isFalse);

      final enabledExplicitly = defaultSettings.copyWith(enablePs5ControllerPricing: true);
      expect(enabledExplicitly.isPs5ControllerPricingEnabled(clubName: 'Snooker & Billiards Club'), isTrue);
    });
  });

  group('Charge & Overtime Calculation Tests', () {
    const regularPs5 = TableModel(
      id: 'ps5_1',
      name: 'PS5 1',
      type: TableType.ps5,
    );
    const pricing = PricingSettings();
    const gameConfig = GameSettings(enablePs5ControllerPricing: true, enableOvertimeBilling: true);

    test('1.5 Hours calculation with 3 controllers', () {
      final breakdown = TablePricingConfig.calculateCharge(
        table: regularPs5,
        gameType: GameType.standard,
        billingType: BillingType.oneHourThirty,
        activeSeconds: 90 * 60, // Exactly 90 mins
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: gameConfig,
        playersCount: 3,
      );

      expect(breakdown.baseCharge, 570.0);
      expect(breakdown.overtimeMinutes, 0);
      expect(breakdown.overtimeCharge, 0.0);
      expect(breakdown.totalCharge, 570.0);
    });

    test('1.5 Hours overtime calculation past 90 minutes', () {
      final breakdown = TablePricingConfig.calculateCharge(
        table: regularPs5,
        gameType: GameType.standard,
        billingType: BillingType.oneHourThirty,
        activeSeconds: (90 + 10) * 60, // 10 minutes overtime
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: gameConfig,
        playersCount: 2, // 2 controllers = 390 base
      );

      expect(breakdown.baseCharge, 390.0);
      expect(breakdown.overtimeMinutes, 10);
      expect(breakdown.overtimeCharge, greaterThan(0.0));
    });
  });

  group('Resource Pricing Badges for PS5', () {
    const fallback = PricingSettings();

    test('Regular PS5 badges show 1h, 30m, and 1.5h standard rates', () {
      const ps5 = TableModel(
        id: 'ps5_1',
        name: 'PS5 1',
        type: TableType.ps5,
      );

      final badges = resolveTablePriceBadges(ps5, fallback);
      expect(badges.any((b) => b.label == '1h: ₹200–₹480 (1-4 Ctrls)'), isTrue);
      expect(badges.any((b) => b.label == '30m: ₹100–₹280 (1-4 Ctrls)'), isTrue);
      expect(badges.any((b) => b.label == '1.5h: ₹300–₹760 (1-4 Ctrls)'), isTrue);
    });

    test('Basement 4 PS5 badges show discounted single controller rates', () {
      const b4Ps5 = TableModel(
        id: 'ps5_12',
        name: 'PS5 12',
        type: TableType.ps5,
      );

      final badges = resolveTablePriceBadges(b4Ps5, fallback);
      expect(badges.any((b) => b.label == 'Basement 4 Rates'), isTrue);
      expect(badges.any((b) => b.label == '1h: ₹150–₹480 (1-4 Ctrls)'), isTrue);
      expect(badges.any((b) => b.label == '30m: ₹80–₹280 (1-4 Ctrls)'), isTrue);
      expect(badges.any((b) => b.label == '1.5h: ₹225–₹760 (1-4 Ctrls)'), isTrue);
    });
  });

  group('Arcade Gaming Tiered Controller & Duration Pricing', () {
    const regularArcade = TableModel(
      id: 'arc_1',
      name: 'Arcade 1',
      type: TableType.arcade,
    );

    const b4Arcade = TableModel(
      id: 'arc_12',
      name: 'Arcade 12',
      type: TableType.arcade,
    );

    const gameConfig = GameSettings(enablePs5ControllerPricing: true);
    const pricing = PricingSettings();

    test('Arcade rates match PS5 controller-tiered pricing matrix', () {
      // 1 hour
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHour,
        controllers: 1,
      ), 200.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHour,
        controllers: 2,
      ), 240.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHour,
        controllers: 3,
      ), 360.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHour,
        controllers: 4,
      ), 480.0);

      // 1.5 hours
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHourThirty,
        controllers: 1,
      ), 300.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHourThirty,
        controllers: 2,
      ), 390.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHourThirty,
        controllers: 3,
      ), 570.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.oneHourThirty,
        controllers: 4,
      ), 760.0);

      // 30 min
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.halfHour,
        controllers: 1,
      ), 100.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.halfHour,
        controllers: 2,
      ), 150.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.halfHour,
        controllers: 3,
      ), 220.0);
      expect(TablePricingConfig.getPs5TieredRate(
        table: regularArcade,
        billingType: BillingType.halfHour,
        controllers: 4,
      ), 280.0);
    });

    test('Basement 4 Arcade table applies special single-controller rate', () {
      expect(TablePricingConfig.isBasement4Ps5(b4Arcade), isTrue);

      expect(TablePricingConfig.getPs5TieredRate(
        table: b4Arcade,
        billingType: BillingType.oneHour,
        controllers: 1,
      ), 150.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: b4Arcade,
        billingType: BillingType.halfHour,
        controllers: 1,
      ), 80.0);

      expect(TablePricingConfig.getPs5TieredRate(
        table: b4Arcade,
        billingType: BillingType.oneHourThirty,
        controllers: 1,
      ), 225.0);

      // 2 controllers remain normal
      expect(TablePricingConfig.getPs5TieredRate(
        table: b4Arcade,
        billingType: BillingType.oneHour,
        controllers: 2,
      ), 240.0);
    });

    test('Arcade calculateCharge handles tiered controller pricing', () {
      final breakdown = TablePricingConfig.calculateCharge(
        table: regularArcade,
        gameType: GameType.standard,
        billingType: BillingType.oneHourThirty,
        activeSeconds: 90 * 60,
        framesPlayed: 0,
        pricingConfig: pricing,
        gameConfig: gameConfig,
        playersCount: 4,
      );

      expect(breakdown.baseCharge, 760.0);
      expect(breakdown.totalCharge, 760.0);
    });
  });
}
