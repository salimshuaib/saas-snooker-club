import re

with open('lib/features/games/providers/games_providers.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add to GameSessionController
add_method = '''  Future<void> updatePlayerPoints(String gameId, Map<String, int> playerPoints) async {
    try {
      await _repo.updatePlayerPoints(gameId, playerPoints);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pauseGame(String gameId, String tableId) async {'''

content = content.replace("  Future<void> pauseGame(String gameId, String tableId) async {", add_method)

with open('lib/features/games/providers/games_providers.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/features/games/data/games_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

repo_method = '''  Future<void> updatePlayerPoints(String gameId, Map<String, int> playerPoints) async {
    if (AppConfig.guardWrite('GamesRepository.updatePlayerPoints')) return;
    await _gamesRef.doc(gameId).update({
      'playerPoints': playerPoints,
    });
  }

  Future<void> updateOrders(String gameId, List<GameOrder> orders) async {'''

content = content.replace("  Future<void> updateOrders(String gameId, List<GameOrder> orders) async {", repo_method)

with open('lib/features/games/data/games_repository.dart', 'w', encoding='utf-8') as f:
    f.write(content)
