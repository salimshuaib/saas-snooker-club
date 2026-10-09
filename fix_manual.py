import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('manualGamesTotal: _manualGamesTotal,', '')
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("'manualGamesTotal': session.manualGamesTotal,", "")
content = content.replace("'manualGamesTotal': 0.0,", "")
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed manualGamesTotal error')
