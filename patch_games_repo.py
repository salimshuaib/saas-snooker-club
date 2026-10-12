import re

file_path = 'lib/features/games/data/games_repository.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_code = """  Future<void> updateTable(TableModel table) async {
    if (AppConfig.guardWrite('GamesRepository.updateTable')) return;
    await _tablesRef.doc(table.id).update(table.toMap());
  }"""

    new_code = """  Future<void> updateTable(TableModel table) async {
    if (AppConfig.guardWrite('GamesRepository.updateTable')) return;
    try {
      await _tablesRef.doc(table.id).update(table.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        AppLogger.warning('Table ${table.id} not found for update, likely deleted.');
      } else {
        rethrow;
      }
    }
  }"""

    content = content.replace(old_code, new_code)

    old_status = """  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? activeGameId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateTableStatus')) return;
    await _tablesRef.doc(tableId).update({
      'status': status.name,
      'activeGameId': activeGameId,
    });
  }"""

    new_status = """  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? activeGameId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateTableStatus')) return;
    try {
      await _tablesRef.doc(tableId).update({
        'status': status.name,
        'activeGameId': activeGameId,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        AppLogger.warning('Table $tableId not found for status update, likely deleted.');
      } else {
        rethrow;
      }
    }
  }"""
    
    content = content.replace(old_status, new_status)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched games_repository.dart")
except Exception as e:
    print(f"Error: {e}")
