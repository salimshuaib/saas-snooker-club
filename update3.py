import os, glob

files = [
    'c:/Users/Shuai/Desktop/Saas Snooker Club/lib/features/dashboard/presentation/screens/running_tables_screen.dart',
    'c:/Users/Shuai/Desktop/Saas Snooker Club/lib/features/games/presentation/screens/table_details_screen.dart',
    'c:/Users/Shuai/Desktop/Saas Snooker Club/lib/features/games/presentation/screens/billing_screen.dart',
    'c:/Users/Shuai/Desktop/Saas Snooker Club/lib/features/games/presentation/screens/other_game_details_screen.dart'
]

for path in files:
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # for session object in billing_screen
    content = content.replace('completedRounds: _session.rounds,\\n    );', 'completedRounds: _session.rounds,\\n      customPrice: _session.customPrice,\\n    );')
    # for game object in others
    content = content.replace('completedRounds: game.rounds,\\n    );', 'completedRounds: game.rounds,\\n      customPrice: game.customPrice,\\n    );')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
