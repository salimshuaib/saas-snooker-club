path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\data\games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''  Stream<List<TableModel>> watchTables() {
    return _tablesRef
        
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TableModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }''', '''  Stream<List<TableModel>> watchTables() {
    return _tablesRef.snapshots().map((snapshot) {
      final tables = snapshot.docs
          .map((doc) => TableModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      tables.sort((a, b) => a.order.compareTo(b.order));
      return tables;
    });
  }''')

content = content.replace('''  Stream<List<TableModel>> watchAllTablesManagement() {
    return _tablesRef
        
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TableModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }''', '''  Stream<List<TableModel>> watchAllTablesManagement() {
    return _tablesRef.snapshots().map((snapshot) {
      final tables = snapshot.docs
          .map((doc) => TableModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      tables.sort((a, b) => a.order.compareTo(b.order));
      return tables;
    });
  }''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
