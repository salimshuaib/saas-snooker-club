import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/presentation/screens/resource_management_screen.dart';

void main() {
  const fallback = PricingSettings(
    snookerOneHour: 270.0,
    snookerHalfHour: 150.0,
    snookerPerMinute: 4.5,
    americanPoolOneHour: 200.0,
    americanPoolHalfHour: 120.0,
    americanPoolPerMinute: 3.5,
    americanPoolPerFrame: 60.0,
    arcadeCoinPrice: 20.0,
  );

  group('Table Pricing Resolution & Disabled Filter', () {
    test('Shows only enabled pricing options and omits disabled ones', () {
      // American pool table with perFrame enabled, 1hr enabled, but 30m disabled and perMinute disabled
      const table = TableModel(
        id: 'pool_1',
        name: 'American Pool 1',
        type: TableType.americanPool,
        billingOptions: {
          'perFrame': TableBillingOption(enabled: true, price: 60.0),
          'oneHour': TableBillingOption(enabled: true, price: 200.0),
          'halfHour': TableBillingOption(enabled: false, price: 120.0),
          'perMinute': TableBillingOption(enabled: false, price: 3.5),
          'overtime': TableBillingOption(enabled: true, price: 4.0),
        },
      );

      final badges = resolveTablePriceBadges(table, fallback);
      final labels = badges.map((b) => b.label).toList();

      expect(labels.contains('₹60/frame'), isTrue);
      expect(labels.contains('₹200/hr'), isTrue);
      expect(labels.contains('OT: ₹4/min'), isTrue);

      // Disabled options MUST NOT be shown
      expect(labels.any((l) => l.contains('30m')), isFalse);
      expect(labels.any((l) => l == '₹3.50/min'), isFalse);
    });

    test('Arcade games show only coin price when enabled', () {
      const table = TableModel(
        id: 'arc_1',
        name: 'Arcade 1',
        type: TableType.arcade,
        billingOptions: {
          'perCoin': TableBillingOption(enabled: true, price: 25.0),
        },
      );

      final badges = resolveTablePriceBadges(table, fallback);
      final labels = badges.map((b) => b.label).toList();

      expect(labels, ['₹25/coin']);
    });

    test('Minimum bill is shown when enabled and hidden when disabled', () {
      const tableWithMin = TableModel(
        id: 'pool_1',
        name: 'American Pool 1',
        type: TableType.americanPool,
        isMinimumBillEnabled: true,
        minimumBillAmount: 50.0,
        billingOptions: {
          'perFrame': TableBillingOption(enabled: true, price: 60.0),
        },
      );

      final badgesWithMin = resolveTablePriceBadges(tableWithMin, fallback);
      expect(badgesWithMin.map((b) => b.label).contains('Min: ₹50'), isTrue);

      const tableNoMin = TableModel(
        id: 'pool_2',
        name: 'American Pool 2',
        type: TableType.americanPool,
        isMinimumBillEnabled: false,
        minimumBillAmount: 50.0,
        billingOptions: {
          'perFrame': TableBillingOption(enabled: true, price: 60.0),
        },
      );

      final badgesNoMin = resolveTablePriceBadges(tableNoMin, fallback);
      expect(badgesNoMin.map((b) => b.label).contains('Min: ₹50'), isFalse);
    });

    test('Tables with null or empty billingOptions fallback to default pricing badges', () {
      const tableEmpty = TableModel(
        id: 'pool_empty',
        name: 'American Pool 1',
        type: TableType.americanPool,
        billingOptions: {},
      );

      final badges = resolveTablePriceBadges(tableEmpty, fallback);
      final labels = badges.map((b) => b.label).toList();

      expect(labels.contains('₹60/frame'), isTrue);
      expect(labels.contains('₹200/hr'), isTrue);
      expect(labels.contains('₹120/30m'), isTrue);
      expect(labels.contains('₹3.50/min'), isTrue);
    });

    test('Arcade games support 1 Hour, Half Hour, Extra Controllers and Coins badges', () {
      const table = TableModel(
        id: 'arc_custom',
        name: 'Arcade 1',
        type: TableType.arcade,
        billingOptions: {
          'oneHour': TableBillingOption(enabled: true, price: 200.0, extraCharge: 40.0),
          'halfHour': TableBillingOption(enabled: true, price: 100.0, extraCharge: 50.0),
          'perCoin': TableBillingOption(enabled: true, price: 20.0),
        },
      );

      final badges = resolveTablePriceBadges(table, fallback);
      final labels = badges.map((b) => b.label).toList();

      expect(labels.contains('1h: ₹200–₹480 (1-4 Ctrls)'), isTrue);
      expect(labels.contains('30m: ₹100–₹280 (1-4 Ctrls)'), isTrue);
      expect(labels.contains('₹20/coin'), isTrue);
    });
  });
}
