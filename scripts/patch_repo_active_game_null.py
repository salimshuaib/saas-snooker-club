import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'activeGameId': null,", "'activeGameId': null, 'isTimeNotSure': false,")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched games_repository.dart to reset isTimeNotSure on table free')
