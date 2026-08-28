import os

def add_cancel_game():
    repo_path = 'lib/features/games/data/games_repository.dart'
    if os.path.exists(repo_path):
        with open(repo_path, 'r', encoding='utf-8') as f:
            repo_content = f.read()
        
        if 'Future<void> cancelGame' not in repo_content:
            cancel_method = """  /// Cancel an active game. Restores inventory and frees the table.
  Future<void> cancelGame(String gameId, String tableId, List<GameOrder> orders) async {
    if (AppConfig.guardWrite('GamesRepository.cancelGame')) return;
    
    final batch = _db.batch();
    
    // 1. Restore inventory
    if (orders.isNotEmpty) {
      final inventoryRef = _db.collection(FirebaseConstants.inventoryCollection);
      final Map<String, int> stockRestorations = {};
      
      for (final order in orders) {
        for (final item in order.items) {
          stockRestorations[item.itemId] = (stockRestorations[item.itemId] ?? 0) + item.quantity;
        }
      }
      
      for (final entry in stockRestorations.entries) {
        batch.update(inventoryRef.doc(entry.key), {
          'currentStock': FieldValue.increment(entry.value),
        });
      }
    }
    
    // 2. Delete game record
    batch.delete(_gamesRef.doc(gameId));
    
    // 3. Free the table
    batch.update(_tablesRef.doc(tableId), {'status': TableStatus.available.name});
    
    // 4. Audit log
    final auditRef = _db.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'Game Cancelled',
      'recordId': gameId,
      'collection': FirebaseConstants.gamesCollection,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'Active game cancelled. ${orders.length} orders restocked.',
      ..._enrichWithStaff(),
    });
    
    await batch.commit();
  }

  /// Mark the game as billing (about to finalize)."""
            
            repo_content = repo_content.replace('  /// Mark the game as billing (about to finalize).', cancel_method)
            
            with open(repo_path, 'w', encoding='utf-8') as f:
                f.write(repo_content)

    ctrl_path = 'lib/features/games/providers/games_providers.dart'
    if os.path.exists(ctrl_path):
        with open(ctrl_path, 'r', encoding='utf-8') as f:
            ctrl_content = f.read()
            
        if 'Future<void> cancelGame' not in ctrl_content:
            cancel_method_ctrl = """  Future<void> resumeGame(String gameId, String tableId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(gamesRepositoryProvider).resumeGame(gameId, tableId);
    });
  }

  Future<void> cancelGame(String gameId, String tableId, List<GameOrder> orders) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(gamesRepositoryProvider).cancelGame(gameId, tableId, orders);
    });
  }"""
            ctrl_content = ctrl_content.replace("""  Future<void> resumeGame(String gameId, String tableId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(gamesRepositoryProvider).resumeGame(gameId, tableId);
    });
  }""", cancel_method_ctrl)
            
            with open(ctrl_path, 'w', encoding='utf-8') as f:
                f.write(ctrl_content)
                
if __name__ == '__main__':
    add_cancel_game()
