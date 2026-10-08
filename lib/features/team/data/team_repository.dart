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

  CollectionReference<Map<String, dynamic>> get _attendanceRef {
    if (clubId == null)
      throw Exception('clubId cannot be null for TeamRepository');
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.attendanceCollection);
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

  Future<void> checkInStaff(String uid) async {
    final staff = await getStaffMember(uid);
    if (staff == null) return;
    
    final batch = _db.batch();
    
    // Update staff document
    batch.update(_teamRef.doc(uid), {
      'isCheckedIn': true,
      'lastCheckInTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create an attendance log
    final now = DateTime.now();
    final logId = '${uid}_${now.millisecondsSinceEpoch}';
    final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final logRef = _attendanceRef.doc(logId);
    batch.set(logRef, {
      'staffId': uid,
      'staffName': staff.name,
      'checkInTime': FieldValue.serverTimestamp(),
      'checkOutTime': null,
      'dateString': dateString,
      'autoCheckedOut': false,
      'editedByOwner': false,
    });

    await batch.commit();
  }

  Future<void> checkOutStaff(String uid, {bool autoCheckedOut = false}) async {
    final batch = _db.batch();
    
    // Update staff document
    batch.update(_teamRef.doc(uid), {
      'isCheckedIn': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Find the open attendance logs and close them
    final query = await _attendanceRef
        .where('staffId', isEqualTo: uid)
        .where('checkOutTime', isNull: true)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'checkOutTime': FieldValue.serverTimestamp(),
        'autoCheckedOut': autoCheckedOut,
      });
    }

    await batch.commit();
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
