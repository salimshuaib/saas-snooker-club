import sys
import re

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_method = '''  Future<void> toggleTimeNotSure(String gameId, bool isNotSure) async {
    AppConfig.guardWrite('GamesRepository.toggleTimeNotSure');
    await _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(gameId)
        .update({'isTimeNotSure': isNotSure});
  }

'''

idx = content.find('  Future<void> settlePendingBill')
if idx != -1:
    content = content[:idx] + new_method + content[idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched games_repository.dart')
