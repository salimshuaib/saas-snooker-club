import os

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

old_fields = """      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'grandTotal': session.grandTotal,"""

new_fields = """      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'grandTotal': session.grandTotal,
      'roundedAmount': session.roundedAmount,
      'finalAmount': session.finalAmount,"""

c = c.replace(old_fields, new_fields)

# Also check updateGamePaymentMethods to see if it updates them
# But maybe we don't need to change it there if they are immutable after endGame

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
