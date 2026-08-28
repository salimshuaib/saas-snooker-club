path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\data\games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_seed = '''  Future<void> seedTablesIfEmpty() async {
    if (AppConfig.guardWrite('GamesRepository.seedTablesIfEmpty')) return;
    try {
      // Only seed if the club has ZERO tables. 
      // Do not sync missing tables if the club has intentionally deleted some.
      final snapshot = await _tablesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Club already has tables, leave them alone.
      }

      final tables = TablesConfig.defaultTables;

      AppLogger.info('Seeding default tables for new club: \ tables...');
      final batch = _db.batch();
      for (int i = 0; i < tables.length; i++) {
        batch.set(_tablesRef.doc(tables[i].id), {
          ...tables[i].toMap(),
          'order': i,
        });
      }
      await batch.commit();
      AppLogger.info('Default tables seeded successfully.');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.warning(
          'Firestore permission denied — tables not seeded. '
          'Update Firestore rules to: allow read, write: if request.auth != null;',
        );
      } else {
        AppLogger.error('Failed to seed tables: \');
      }
    } catch (e) {
      AppLogger.error('Failed to seed tables: \');
    }
  }'''

import re
content = re.sub(r'  Future<void> seedTablesIfEmpty\(\) async \{.*?    \} catch \(e\) \{\s*AppLogger\.error\(\'Failed to seed tables: \\'\);\s*\}\s*\}', new_seed, content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
