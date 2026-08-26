import os

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Replace session.grandTotal with amountToPay in the method
# But first define amountToPay inside updateGamePaymentMethods

c = c.replace(
    "final updateMap = <String, dynamic>{};",
    "final updateMap = <String, dynamic>{};\n    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;"
)

# Now in the split part
c = c.replace(
    "(session.grandTotal ?? 0.0) / newPlayerPaymentMethods.length;",
    "amountToPay / newPlayerPaymentMethods.length;"
)

# Now in the non-split part append
c = c.replace(
    "amount: session.grandTotal ?? 0.0,",
    "amount: amountToPay,"
)

# Now in the final Map update
c = c.replace(
    "updateMap['paidAmount'] = session.grandTotal;",
    "updateMap['paidAmount'] = amountToPay;"
)
c = c.replace(
    "updateMap['remainingAmount'] = session.grandTotal;",
    "updateMap['remainingAmount'] = amountToPay;"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
