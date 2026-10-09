import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

wipe_code = '''
  Future<void> wipeCueZoneData() async {
    print('Starting wipe of CueZone data for club: $clubId');
    final batch = _db.batch();

    // 1. Delete all games
    final gamesSnap = await _db.collection('clubs').doc(clubId).collection('games').get();
    for (var doc in gamesSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${gamesSnap.docs.length} games');

    // 2. Reset all tables
    final tablesSnap = await _db.collection('clubs').doc(clubId).collection('tables').get();
    for (var doc in tablesSnap.docs) {
      batch.update(doc.reference, {
        'status': 'available',
        'activeGameId': null,
        'isTimeNotSure': false,
      });
    }
    print('Resetting ${tablesSnap.docs.length} tables');

    // 3. Delete all player profiles (Khata customers)
    final playersSnap = await _db.collection('clubs').doc(clubId).collection('customers').get();
    for (var doc in playersSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${playersSnap.docs.length} players');

    // 4. Delete all credit transactions
    final creditSnap = await _db.collection('clubs').doc(clubId).collection('credit_history').get();
    for (var doc in creditSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${creditSnap.docs.length} credit history entries');

    await batch.commit();
    print('Wipe complete!');
  }
}'''

content = content.replace('      return list;\n    });\n  }\n\n}', '      return list;\n    });\n  }' + wipe_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched games_repository.dart')
