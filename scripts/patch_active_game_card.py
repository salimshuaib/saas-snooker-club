import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
imports = """import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/games/presentation/widgets/alarm_setup_sheet.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';
import 'package:snooker_club/features/games/presentation/widgets/pending_bill_customer_sheet.dart';"""

if "import 'package:snooker_club/core/utils/billing_utils.dart';" not in content:
    content = content.replace(
        """import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/games/presentation/widgets/alarm_setup_sheet.dart';""",
        imports
    )

# Replace the button
old_button = """        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.edit_document, size: 16),
                label: const Text(
                  'Manual Entry',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final employeeId = ref.read(currentStaffProvider).value?.id ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManualGameSetupScreen(
                        employeeId: employeeId,
                        isCompletedGame: true,
                        initialTable: widget.table,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),"""

new_button = """        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  foregroundColor: Colors.orange.shade700,
                ),
                icon: const Icon(Icons.pending_actions, size: 16),
                label: const Text(
                  'Mark as Pending',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _handleMarkAsPending(game, context),
              ),
            ),
          ],
        ),"""

if old_button in content:
    content = content.replace(old_button, new_button)
    print("Replaced Manual Entry button.")
else:
    print("WARNING: Could not find old_button.")

new_func = """
  Future<void> _handleMarkAsPending(GameSession game, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) async {
            Navigator.of(ctx).pop();
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
            
            await ref.read(gamesRepositoryProvider).markAsPendingBill(
              finalSession,
              customerId: id,
              customerName: name,
            );
          },
        ),
      ),
    );
  }
"""

if '_handleMarkAsPending' not in content:
    content = content.replace('class _RoundCompletionDialog', new_func + '\nclass _RoundCompletionDialog')
    print("Added _handleMarkAsPending function.")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Script completed.")
