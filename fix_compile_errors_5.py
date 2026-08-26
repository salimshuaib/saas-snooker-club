import os

def fix_game_types():
    # 1. billing_screen.dart
    path = 'lib/features/games/presentation/screens/billing_screen.dart'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            c = f.read()
        c = c.replace(
            "      tableType: _session.tableType,\n      billingType: _session.billingType,",
            "      tableType: _session.tableType,\n      gameType: _session.gameType,\n      billingType: _session.billingType,"
        )
        c = c.replace(
            "      tableType: _session.tableType,\n        billingType: _session.billingType,",
            "      tableType: _session.tableType,\n        gameType: _session.gameType,\n        billingType: _session.billingType,"
        )
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)

    # 2. table_details_screen.dart
    path = 'lib/features/games/presentation/screens/table_details_screen.dart'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            c = f.read()
        c = c.replace(
            "                  tableType: game.tableType,\n                  billingType: game.billingType,",
            "                  tableType: game.tableType,\n                  gameType: game.gameType,\n                  billingType: game.billingType,"
        )
        c = c.replace(
            "            game.tableType,\n            game.billingType,",
            "            game.tableType,\n            game.gameType,\n            game.billingType,"
        )
        c = c.replace(
            "            game.tableType,\n            game.gameType,\n            game.billingType,\n            pricing,",
            "            game.tableType,\n            game.gameType,\n            game.billingType,\n            pricing,"
        )
        # Fix lines 822/845
        c = c.replace(
            "        TablePricingConfig.getPrice(\n            game.tableType,\n            game.billingType,\n            pricing,\n          )",
            "        TablePricingConfig.getPrice(\n            game.tableType,\n            game.gameType,\n            game.billingType,\n            pricing,\n          )"
        )
        c = c.replace(
            "    final double perMinRate = TablePricingConfig.getPerMinutePrice(\n          game.tableType,\n          pricing,\n        );",
            "    final double perMinRate = TablePricingConfig.getPerMinutePrice(\n          game.tableType,\n          game.gameType,\n          pricing,\n        );"
        )
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)
            
fix_game_types()
