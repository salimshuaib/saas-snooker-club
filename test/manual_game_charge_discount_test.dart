import 'package:flutter_test/flutter_test.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

void main() {
  ManualGameCharge createCharge({
    required String id,
    double discountAmount = 0,
  }) {
    return ManualGameCharge(
      id: id,
      tableId: 'table-1',
      tableName: 'Table 1',
      tableType: TableType.snooker,
      gameType: GameType.standard,
      billingType: BillingType.perMinute,
      calculatedAmount: 100,
      discountAmount: discountAmount,
    );
  }

  test('manual game discount round-trips and caps at the charge amount', () {
    final charge = createCharge(id: 'game-1', discountAmount: 150);
    final restored = ManualGameCharge.fromMap(charge.toMap());

    expect(restored.discountAmount, 150);
    expect(restored.appliedDiscountAmount, 100);
    expect(restored.finalAmount, 0);
  });

  test('split charges can scale their price and discount together', () {
    final splitCharge = createCharge(
      id: 'game-1',
      discountAmount: 25,
    ).copyWith(calculatedAmount: 50, discountAmount: 12.5);

    expect(splitCharge.finalAmount, 37.5);
  });

  test('grouped manual games report aggregate discounts and final amounts', () {
    final groups = [
      createCharge(id: 'game-1', discountAmount: 25),
      createCharge(id: 'game-2', discountAmount: 25),
    ].grouped();

    expect(groups, hasLength(1));
    expect(groups.single.totalAmount, 200);
    expect(groups.single.totalDiscountAmount, 50);
    expect(groups.single.finalAmount, 150);
  });

  test('current game discount is stored with the session', () {
    final session = GameSession(
      id: 'session-1',
      tableId: 'table-1',
      tableName: 'Table 1',
      tableType: TableType.snooker,
      mode: GameMode.solo,
      billingType: BillingType.perMinute,
      matchType: MatchType.friendly,
      teamA: const ['Player'],
      status: TableStatus.billing,
      startTime: DateTime(2026, 10, 8),
      date: '2026-10-08',
      currentGameDiscountAmount: 20,
      waitlistPlayers: const [
        WaitlistPlayer(id: 'player-2', name: 'Next Player'),
        WaitlistPlayer(name: 'Guest Player'),
      ],
    );

    final restored = GameSession.fromMap(session.toMap());

    expect(restored.currentGameDiscountAmount, 20);
    expect(restored.waitlistPlayers, hasLength(2));
    expect(restored.waitlistPlayers.first.id, 'player-2');
    expect(restored.waitlistPlayers.first.name, 'Next Player');
    expect(restored.waitlistPlayers.last.id, isNull);
    expect(restored.waitlistPlayers.last.name, 'Guest Player');
  });
}
