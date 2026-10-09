import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_handler = '''
  Future<void> _handleMarkAsPending(GameSession game, BuildContext context) async {
    final selectedPlayers = await showDialog<List<PlayerSelection>?>(
      context: context,
      builder: (ctx) => const MarkPendingDialog(),
    );

    if (selectedPlayers == null || selectedPlayers.isEmpty) return;

    if (!context.mounted) return;

    // Wait slightly to let dialog close
    await Future.delayed(const Duration(milliseconds: 100));

    final appSettings = ref.read(appSettingsProvider);

    final charge = TablePricingConfig.calculateCharge(
      table: widget.table,
      gameType: game.gameType,
      billingType: game.billingType,
      activeSeconds: game.activeSeconds,
      framesPlayed: math.max(game.framesPlayed, game.totalFrames),
      pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
      gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: game.rounds,
      customPrice: game.customPrice,
      customExtraCharge: game.customExtraCharge,
      playersCount: game.allPlayers.length,
      coinQuantity: game.coinQuantity,
      isMinimumBillEnabled: game.isMinimumBillEnabled,
      minimumBillAmount: game.minimumBillAmount,
    );

    final gameCharge = charge.totalCharge;
    final manualGamesTotal = game.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount);
    final ordersTotal = game.orders.fold<double>(0, (s, o) => s + o.total);
    final grandTotal = gameCharge + ordersTotal + manualGamesTotal;
    final finalTotal = math.max(0.0, grandTotal - (game.discountAmount ?? 0.0));

    final roundedTotal = BillingUtils.roundAmount(finalTotal);

    final finalSession = game.copyWith(
      endTime: DateTime.now(),
      gameCharge: gameCharge,
      baseGameCharge: charge.baseCharge,
      overtimeMinutes: charge.overtimeMinutes,
      overtimeCharge: charge.overtimeCharge,
      ordersTotal: ordersTotal,
      grandTotal: finalTotal,
      roundedAmount: roundedTotal,
      finalAmount: roundedTotal,
    );

    final repo = ref.read(gamesRepositoryProvider);

    if (selectedPlayers.length == 1) {
      await repo.markAsPendingBill(
        finalSession,
        customerId: selectedPlayers[0].id!,
        customerName: selectedPlayers[0].name,
      );
    } else {
      final playerMaps = selectedPlayers.map((p) => {'id': p.id!, 'name': p.name}).toList();
      await repo.markAsPendingBillWithSplits(finalSession, playerMaps);
    }
  }
}
'''

# We want to replace the LAST closing brace of _ActiveGameCardState.
# But wait, there is `class _ActiveGameCardState ...` and then another class `_AlarmIcon` at the bottom.
# Let's find `class _AlarmIcon` and insert BEFORE it.

idx = content.rfind('\nclass _AlarmIcon')
if idx != -1:
    # Go back to the closing brace of the previous class
    close_brace = content.rfind('}', 0, idx)
    if close_brace != -1:
        content = content[:close_brace] + new_handler + content[idx:]

import1 = "import 'package:snooker_club/features/games/presentation/widgets/pending_bill_customer_sheet.dart';"
import2 = "import 'package:snooker_club/features/games/presentation/widgets/mark_pending_dialog.dart';\nimport 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';"
content = content.replace(import1, import2)

if import2 not in content:
    content = content.replace("import 'package:snooker_club/features/games/presentation/widgets/alarm_setup_sheet.dart';", "import 'package:snooker_club/features/games/presentation/widgets/alarm_setup_sheet.dart';\n" + import2)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched strictly')
