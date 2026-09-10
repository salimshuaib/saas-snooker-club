import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace _playerPaymentMethods accesses
code = code.replace('_playerPaymentMethods[player] ?? PaymentMethod.cash', '_playerPaymentSplits[player] ?? {PaymentMethod.cash: amount}')
code = code.replace('_playerPaymentMethods[player] = method', '_playerPaymentSplits[player] = {method: liabilities[player] ?? 0.0}')

# Now replace the Row with buttons
row_start = code.find('Row(\n                    children: PaymentMethod.values.map((method) {')

