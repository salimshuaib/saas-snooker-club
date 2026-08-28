import os

def fix_cancel_game():
    repo_path = 'lib/features/games/data/games_repository.dart'
    if os.path.exists(repo_path):
        with open(repo_path, 'r', encoding='utf-8') as f:
            repo_content = f.read()
            
        old_audit = """      'details': 'Active game cancelled. ${orders.length} orders restocked.',
      ..._enrichWithStaff(),
    });"""
        new_audit = """      'details': 'Active game cancelled. ${orders.length} orders restocked.',
      'staffId': currentStaff?.id,
      'staffName': currentStaff?.name,
    });"""
        repo_content = repo_content.replace(old_audit, new_audit)
        
        old_orders = """      for (final order in orders) {
        for (final item in order.items) {
          stockRestorations[item.itemId] = (stockRestorations[item.itemId] ?? 0) + item.quantity;
        }
      }"""
        new_orders = """      for (final order in orders) {
        stockRestorations[order.productId] = (stockRestorations[order.productId] ?? 0) + int.parse(order.quantity.toString());
      }"""
        repo_content = repo_content.replace(old_orders, new_orders)
        
        with open(repo_path, 'w', encoding='utf-8') as f:
            f.write(repo_content)
            
    prov_path = 'lib/features/games/providers/games_providers.dart'
    if os.path.exists(prov_path):
        with open(prov_path, 'r', encoding='utf-8') as f:
            prov_content = f.read()
            
        old_resume = """  Future<void> resumeGame(String gameId, String tableId) async {
    try {
      await _repo.resumeGame(gameId, tableId, DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }"""
        new_resume = """  Future<void> resumeGame(String gameId, String tableId) async {
    try {
      await _repo.resumeGame(gameId, tableId, DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelGame(String gameId, String tableId, List<GameOrder> orders) async {
    try {
      await _repo.cancelGame(gameId, tableId, orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }"""
        prov_content = prov_content.replace(old_resume, new_resume)
        
        with open(prov_path, 'w', encoding='utf-8') as f:
            f.write(prov_content)

if __name__ == '__main__':
    fix_cancel_game()
