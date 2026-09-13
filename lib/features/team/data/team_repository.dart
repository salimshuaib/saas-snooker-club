import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snooker_club/core/error/app_exception.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

import 'package:snooker_club/core/constants/firebase_constants.dart';

class TeamRepository {
  final FirebaseFirestore _db;
  final String? clubId;

  TeamRepository({FirebaseFirestore? db, this.clubId})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teamRef {
    if (clubId == null)
      throw Exception('clubId cannot be null for TeamRepository');
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('team_members');
  }

  Stream<List<StaffMember>> watchTeamMembers() {
    return _teamRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffMember.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<StaffMember?> watchStaffMember(String uid) {
    return _teamRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StaffMember.fromMap(doc.data()!, doc.id);
    });
  }

  Future<StaffMember?> getStaffMember(String uid) async {
    final doc = await _teamRef.doc(uid).get();
    if (!doc.exists) return null;
    return StaffMember.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateStaffMember(StaffMember member) async {
    await _teamRef.doc(member.id).set(member.toMap(), SetOptions(merge: true));
  }

  Future<void> disableStaffMember(String uid) async {
    await _teamRef.doc(uid).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> enableStaffMember(String uid) async {
    await _teamRef.doc(uid).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addStaffMember({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Create a temporary Firebase app to create the user without logging out the current admin
      tempApp = await Firebase.initializeApp(
        name: 'temp_auth_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;

      final now = DateTime.now();
      final newMember = StaffMember(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _db.batch();
      batch.set(_teamRef.doc(uid), newMember.toMap());
      batch.set(
        _db.collection(FirebaseConstants.userClubsCollection).doc(uid),
        {'clubId': clubId, 'role': role.name},
      );
      await batch.commit();

      await tempApp.delete();
    } on FirebaseAuthException catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
      throw AuthException(
        message: e.message ?? 'Failed to create staff account',
      );
    } catch (e) {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
      throw UnknownException(
        message: 'An unexpected error occurred while creating the account.',
      );
    }
  }
}
