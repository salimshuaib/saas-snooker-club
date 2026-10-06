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
    final currentClubId = clubId;
    if (currentClubId == null) {
      throw StateError('clubId cannot be null for TeamRepository');
    }
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(currentClubId)
        .collection('attendance_logs');
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
    final staffRef = _teamRef.doc(uid);
    await _db.runTransaction((transaction) async {
      final staffSnapshot = await transaction.get(staffRef);
      if (!staffSnapshot.exists) {
        throw StateError('Cannot check in missing staff member $uid');
      }
      if (staffSnapshot.data()?['isCheckedIn'] == true) return;

      transaction.update(staffRef, {
        'isCheckedIn': true,
        'lastCheckInTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> checkOutStaff(String uid) async {
    final staffRef = _teamRef.doc(uid);
    final attendanceRef = _attendanceRef.doc();

    await _db.runTransaction((transaction) async {
      final staffSnapshot = await transaction.get(staffRef);
      if (!staffSnapshot.exists) {
        throw StateError('Cannot check out missing staff member $uid');
      }

      final staffData = staffSnapshot.data()!;
      if (staffData['isCheckedIn'] != true) return;

      final checkOutTime = DateTime.now();
      final checkInValue = staffData['lastCheckInTime'];
      final DateTime? checkInTime = switch (checkInValue) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      };

      transaction.update(staffRef, {
        'isCheckedIn': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (checkInTime != null && !checkOutTime.isBefore(checkInTime)) {
        final staff = StaffMember.fromMap(staffData, uid);
        transaction.set(
          attendanceRef,
          _attendanceData(staff, checkInTime, checkOutTime),
        );
      }
    });
  }

  Future<void> logAttendance(
    StaffMember staff,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    if (checkOut.isBefore(checkIn)) {
      throw ArgumentError.value(
        checkOut,
        'checkOut',
        'Check-out time cannot be before check-in time',
      );
    }

    await _attendanceRef.add(_attendanceData(staff, checkIn, checkOut));
  }

  Map<String, dynamic> _attendanceData(
    StaffMember staff,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    final month = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
    return {
      'staffId': staff.id,
      'staffName': staff.name,
      'role': staff.role.name,
      'checkInTime': Timestamp.fromDate(checkIn),
      'checkOutTime': Timestamp.fromDate(checkOut),
      'durationMinutes': checkOut.difference(checkIn).inMinutes,
      'month': month,
      'createdAt': FieldValue.serverTimestamp(),
    };
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
