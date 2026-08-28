import os

path = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    """    final roundCost =
        TablePricingConfig.getPrice(
          game.tableType,
          game.billingType,
          pricing,
        ) ??
        0.0;""",
    """    final roundCost =
        TablePricingConfig.getPrice(
          game.tableType,
          game.gameType,
          game.billingType,
          pricing,
        ) ??
        0.0;"""
)

c = c.replace(
    """    final double perMinRate = TablePricingConfig.getPerMinutePrice(
      game.tableType,
      pricing,
    );""",
    """    final double perMinRate = TablePricingConfig.getPerMinutePrice(
      game.tableType,
      game.gameType,
      pricing,
    );"""
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
