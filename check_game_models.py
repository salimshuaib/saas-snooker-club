import os

path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

# Fix uninitialized fields
c = c.replace(
    "  final double? roundedAmount;\n  final double? finalAmount;",
    ""
) # Wait, my previous script added them but didn't initialize them in some constructor?

old_fields = """  final double? ordersTotal;
  final double? grandTotal;
  final double? roundedAmount;
  final double? finalAmount;
  final String? employeeId;"""
  
new_fields = """  final double? ordersTotal;
  final double? grandTotal;
  final double? roundedAmount;
  final double? finalAmount;
  final String? employeeId;"""
# Wait, I did:
#       this.ordersTotal,
#       this.grandTotal,
#       this.roundedAmount,
#       this.finalAmount,
#       this.employeeId,
# But they are still missing in `const GameSession({` ?

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
