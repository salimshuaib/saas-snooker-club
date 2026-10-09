import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# in endGame
content = content.replace("'status': TableStatus.available.name,\n      'activeGameId': null,", "'status': TableStatus.available.name,\n      'activeGameId': null,\n      'isTimeNotSure': false,")

# in cancelGame
content = content.replace("'status': TableStatus.available.name,\n          'activeGameId': null,", "'status': TableStatus.available.name,\n          'activeGameId': null,\n          'isTimeNotSure': false,")

# in markAsPendingBill (already sets activeGameId: null)
content = content.replace("batch.update(tableRef, {'activeGameId': null});", "batch.update(tableRef, {'activeGameId': null, 'isTimeNotSure': false});")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched games_repository.dart resets')
