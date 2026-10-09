import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_method = '''  Future<void> toggleTimeNotSure(String gameId, bool isNotSure) async {
    AppConfig.guardWrite('GamesRepository.toggleTimeNotSure');
    await _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(gameId)
        .update({'isTimeNotSure': isNotSure});
  }'''

new_method = '''  Future<void> toggleTimeNotSure(String tableId, bool isNotSure) async {
    AppConfig.guardWrite('GamesRepository.toggleTimeNotSure');
    await _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.tablesCollection)
        .doc(tableId)
        .update({'isTimeNotSure': isNotSure});
  }'''

content = content.replace(old_method, new_method)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched games_repository.dart')
