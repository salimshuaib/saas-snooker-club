path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\data\games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

methods = '''  Future<void> addTable(TableModel table) async {
    if (AppConfig.guardWrite('GamesRepository.addTable')) return;
    await _tablesRef.doc(table.id).set(table.toMap());
  }

  Future<void> deleteTable(String tableId) async {
    if (AppConfig.guardWrite('GamesRepository.deleteTable')) return;
    await _tablesRef.doc(tableId).delete();
  }
'''

content = content.replace('  Future<void> seedTablesIfEmpty() async {', methods + '\n  Future<void> seedTablesIfEmpty() async {')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
