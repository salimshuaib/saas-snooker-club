import re

def modify_delete(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    delete_target = "batch.delete(_gamesRef.doc(session.id));"
    audit_injection = """batch.delete(_gamesRef.doc(session.id));

        // Audit Log for Deletion
        final auditRef = _db.collection('audit_logs').doc();
        batch.set(auditRef, {
          'id': auditRef.id,
          'action': 'Game Deleted',
          'recordId': session.id,
          'module': 'Games',
          'userId': currentStaff?.id ?? 'Unknown',
          'userName': currentStaff?.name ?? 'Admin',
          'timestamp': FieldValue.serverTimestamp(),
        });"""

    if "Audit Log for Deletion" not in content:
        content = content.replace(delete_target, audit_injection)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_delete('lib/features/games/data/games_repository.dart')
    print("Done")
