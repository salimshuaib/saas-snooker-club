import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix endTime
old_endtime = "'endTime': session.endTime?.toIso8601String() ?? now.toIso8601String(),"
new_endtime = "'endTime': Timestamp.fromDate(session.endTime ?? now),"
if old_endtime in content:
    content = content.replace(old_endtime, new_endtime)
    print("Fixed endTime")
else:
    print("WARNING: Could not find old_endtime")

# Fix table update
old_table = """    // Clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {'activeGameId': null});
    }"""

new_table = """    // Clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {
        'activeGameId': FieldValue.delete(),
        'status': TableStatus.available.name,
      });
    }"""

if old_table in content:
    content = content.replace(old_table, new_table)
    print("Fixed table update")
else:
    print("WARNING: Could not find old_table")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done patching repo.")
