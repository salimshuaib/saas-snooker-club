import os

path = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "if (game.rounds.isNotEmpty) ...[\n                  Text(\n                    'Completed Rounds',",
    "if (game.billingType == BillingType.perFrame && game.rounds.isNotEmpty) ...[\n                  Text(\n                    'Completed Rounds',"
)
c = c.replace(
    "if (game.rounds.isNotEmpty) ...[\n                    Text(\n                      'Completed Rounds',",
    "if (game.billingType == BillingType.perFrame && game.rounds.isNotEmpty) ...[\n                    Text(\n                      'Completed Rounds',"
)

c = c.replace(
    "if (game.gameType == GameType.race) ...[",
    "if (false) ...[  // Disabled: Race games no longer use point tracking"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
