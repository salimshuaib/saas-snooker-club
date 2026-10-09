import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''    final finalTotal = math.max(0.0, grandTotal - (game.discountAmount ?? 0.0));

    final roundedTotal = BillingUtils.roundAmount(finalTotal);

    final finalSession = game.copyWith('''

new_code = '''    final finalTotal = math.max(0.0, grandTotal - (game.discountAmount ?? 0.0));

    // For pending bills, we take games as is without rounding off. 
    // Rounding is applied during final combined settlement.
    final roundedTotal = finalTotal;

    final finalSession = game.copyWith('''

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart for pending bill rounding')
