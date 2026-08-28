import os

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "    // Sync with CreditRepository if credit was involved\n    final creditRepo = CreditRepository(_db);",
    "    // Sync with CreditRepository if credit was involved\n    final creditRepo = CreditRepository(_db);\n    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
