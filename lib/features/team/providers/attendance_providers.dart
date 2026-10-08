import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/team/domain/models/attendance_log.dart';

final staffAttendanceProvider = StreamProvider.family<List<AttendanceLog>, String>((ref, staffId) {
  final clubId = ref.watch(clubIdProvider);
  if (clubId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .collection(FirebaseConstants.attendanceCollection)
      .where('staffId', isEqualTo: staffId)
      .snapshots()
      .map((snapshot) {
        final logs = snapshot.docs.map((doc) => AttendanceLog.fromMap(doc.data(), doc.id)).toList();
        // Sort descending locally to avoid requiring index for now
        logs.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
        return logs;
      });
});

final staffMonthlyStatsProvider = FutureProvider.family<Map<String, int>, (String, DateTime)>((ref, params) async {
  final clubId = ref.watch(clubIdProvider);
  if (clubId == null) return {'games': 0, 'sales': 0};

  final staffId = params.$1;
  final month = params.$2; // representing the first day of the month
  
  final firestore = FirebaseFirestore.instance;
  
  // Calculate start and end of the month
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));

  // Query games run by this staff member (filter by month locally to avoid composite index)
  final gamesQuery = await firestore
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .collection(FirebaseConstants.gamesCollection)
      .where('createdByUserId', isEqualTo: staffId)
      .get();
      
  int gamesCount = 0;
  for (var doc in gamesQuery.docs) {
    final rawStartTime = doc.data()['startTime'];
    DateTime? startTime;
    if (rawStartTime is Timestamp) {
      startTime = rawStartTime.toDate();
    } else if (rawStartTime is String) {
      startTime = DateTime.tryParse(rawStartTime);
    }
    
    if (startTime != null && startTime.isAfter(startOfMonth) && startTime.isBefore(endOfMonth)) {
      gamesCount++;
    }
  }

  // Query quick sales run by this staff member (filter locally)
  final salesQuery = await firestore
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .collection(FirebaseConstants.salesCollection)
      .where('staffId', isEqualTo: staffId)
      .get();
      
  int salesCount = 0;
  for (var doc in salesQuery.docs) {
    final rawTimestamp = doc.data()['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      timestamp = DateTime.tryParse(rawTimestamp);
    }

    if (timestamp != null && timestamp.isAfter(startOfMonth) && timestamp.isBefore(endOfMonth)) {
      salesCount++;
    }
  }

  return {'games': gamesCount, 'sales': salesCount};
});
