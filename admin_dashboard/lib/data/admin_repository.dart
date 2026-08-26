import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_dashboard/models/club.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository());

final clubsStreamProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllClubs();
});

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Club>> watchAllClubs() {
    return _db.collection('clubs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Club.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> toggleClubStatus(String clubId, bool isActive) async {
    await _db.collection('clubs').doc(clubId).update({
      'isActive': isActive,
    });
  }
  
  Future<void> createClub({
    required String clubName,
    required String appName,
    required String ownerName,
    required String ownerEmail,
  }) async {
    FirebaseApp? tempApp;
    try {
      // 1. Create a temporary Firebase app to create the user without logging out the super-admin
      tempApp = await Firebase.initializeApp(
        name: 'temp_auth_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final defaultPassword = 'Password123!'; // Default password for new club owners
      
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: ownerEmail.trim(),
        password: defaultPassword,
      );
      
      final uid = userCredential.user!.uid;
      
      // 2. Setup Firestore Data
      final batch = _db.batch();
      final clubRef = _db.collection('clubs').doc();
      
      final club = Club(
        id: clubRef.id,
        clubName: clubName,
        appName: appName,
        ownerUid: uid,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerPhone: '',
        themeColor: '#1B5E20',
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // Create the Club
      batch.set(clubRef, club.toMap());
      
      // Link the UID to this Club
      batch.set(_db.collection('user_clubs').doc(uid), {
        'clubId': clubRef.id,
        'role': 'owner',
      });
      
      // Add the owner to the club's team_members
      batch.set(clubRef.collection('team_members').doc(uid), {
        'id': uid,
        'name': ownerName,
        'email': ownerEmail,
        'role': 'owner',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      await tempApp.delete();
      
    } catch (e) {
      if (tempApp != null) {
        try { await tempApp.delete(); } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> deleteClub(Club club) async {
    final batch = _db.batch();
    
    // 1. Delete the user_clubs mapping for the owner (so they can no longer login)
    if (club.ownerUid.isNotEmpty) {
      batch.delete(_db.collection('user_clubs').doc(club.ownerUid));
    }
    
    // 2. Delete the main club document
    batch.delete(_db.collection('clubs').doc(club.id));
    
    // Note: This does not delete the Firebase Auth user or the nested subcollections 
    // (games, tables, etc.) because that requires a Firebase Admin SDK (Cloud Function).
    // However, it will remove the club from the dashboard and prevent the owner from logging in.
    
    await batch.commit();
  }
}
