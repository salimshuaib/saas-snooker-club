import os
import re

def add_game_type(path):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    
    # 1. calculateCharge
    c = c.replace(
        "tableType: game.tableType,\n                    billingType: game.billingType,",
        "tableType: game.tableType,\n                    gameType: game.gameType,\n                    billingType: game.billingType,"
    )
    
    c = c.replace(
        "tableType: _session.tableType,\n        billingType: _session.billingType,",
        "tableType: _session.tableType,\n        gameType: _session.gameType,\n        billingType: _session.billingType,"
    )

    c = c.replace(
        "tableType: table.type,\n      billingType: game.billingType,",
        "tableType: table.type,\n      gameType: game.gameType,\n      billingType: game.billingType,"
    )

    # 2. getPrice
    c = c.replace(
        "game.tableType,\n            game.billingType,\n            pricing,",
        "game.tableType,\n            game.gameType,\n            game.billingType,\n            pricing,"
    )
    
    # 3. getPerMinutePrice
    c = c.replace(
        "game.tableType,\n          pricing,\n        );",
        "game.tableType,\n          game.gameType,\n          pricing,\n        );"
    )
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

add_game_type('lib/features/games/presentation/screens/billing_screen.dart')
add_game_type('lib/features/games/presentation/screens/table_details_screen.dart')
add_game_type('lib/features/dashboard/presentation/screens/running_tables_screen.dart')
