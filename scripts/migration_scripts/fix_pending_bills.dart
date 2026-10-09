import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixBadPendingBills(FirebaseFirestore db) async {
  print('Starting fix...');
  final clubsSnap = await db.collection('clubs').get();
  
  for (final clubDoc in clubsSnap.docs) {
    final clubId = clubDoc.id;
    
    // 1. Fix Games with bad endTime
    final gamesSnap = await db.collection('clubs').doc(clubId).collection('games').get();
    for (final gameDoc in gamesSnap.docs) {
      final data = gameDoc.data();
      bool needsUpdate = false;
      final updateData = <String, dynamic>{};
      
      if (data['endTime'] is String) {
        try {
          final dt = DateTime.parse(data['endTime']);
          updateData['endTime'] = Timestamp.fromDate(dt);
          needsUpdate = true;
        } catch (e) {
          print('Could not parse string endTime for game ${gameDoc.id}');
        }
      }
      
      if (needsUpdate) {
        await gameDoc.reference.update(updateData);
        print('Fixed game ${gameDoc.id}');
      }
    }
    
    // 2. Fix Tables stuck in running
    final tablesSnap = await db.collection('clubs').doc(clubId).collection('tables').get();
    for (final tableDoc in tablesSnap.docs) {
      final data = tableDoc.data();
      if (data['status'] == 'running' && data['activeGameId'] == null) {
        await tableDoc.reference.update({'status': 'available'});
        print('Fixed table ${tableDoc.id}');
      }
    }
  }
  
  print('Done fixing bad pending bills.');
}
