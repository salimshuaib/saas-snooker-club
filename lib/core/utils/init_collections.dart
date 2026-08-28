import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';

Future<void> initializeMissingCollections(String clubId) async {
  try {
    final db = FirebaseFirestore.instance;
    final clubRef = db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId);

    // 1. Settings Collection
    final settingsDoc = clubRef
        .collection(FirebaseConstants.settingsCollection)
        .doc('app_settings');
    final settingsSnapshot = await settingsDoc.get();
    if (!settingsSnapshot.exists) {
      await settingsDoc.set(
        const AppSettings().toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Initialized Settings collection for $clubId');
    }

    // 2. Games Collection (Just to ensure the collection exists, we create and delete a dummy doc)
    final gamesRef = clubRef.collection(FirebaseConstants.gamesCollection);
    final gamesSnapshot = await gamesRef.limit(1).get();
    if (gamesSnapshot.docs.isEmpty) {
      final dummyGame = gamesRef.doc('_dummy_init_');
      await dummyGame.set({'_init': true});
      await dummyGame.delete();
      debugPrint('Initialized Games collection for $clubId');
    }

    // 3. Quick Sale Collection
    final qsRef = clubRef.collection('quick_sales');
    final qsSnapshot = await qsRef.limit(1).get();
    if (qsSnapshot.docs.isEmpty) {
      final dummyQs = qsRef.doc('_dummy_init_');
      await dummyQs.set({'_init': true});
      await dummyQs.delete();
      debugPrint('Initialized Quick Sale collection for $clubId');
    }
  } catch (e) {
    debugPrint('Error initializing collections: $e');
  }
}
