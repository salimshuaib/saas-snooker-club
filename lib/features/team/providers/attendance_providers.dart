import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/team/domain/models/attendance_log.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class StaffActivityRecord {
  final DateTime timestamp;
  final double amount;

  const StaffActivityRecord({
    required this.timestamp,
    this.amount = 0.0,
  });
}

class StaffActivityData {
  final List<StaffActivityRecord> games;
  final List<StaffActivityRecord> sales;

  const StaffActivityData({
    required this.games,
    required this.sales,
  });
}

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

final staffActivityDataProvider = FutureProvider.family<StaffActivityData, String>((ref, staffId) async {
  final clubId = ref.watch(clubIdProvider);
  if (clubId == null) return const StaffActivityData(games: [], sales: []);

  final firestore = FirebaseFirestore.instance;

  // Query games run by this staff member
  final gamesQuery = await firestore
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .collection(FirebaseConstants.gamesCollection)
      .where('createdByUserId', isEqualTo: staffId)
      .get();

  final List<StaffActivityRecord> games = [];
  for (var doc in gamesQuery.docs) {
    final data = doc.data();
    final rawStartTime = data['startTime'];
    DateTime? startTime;
    if (rawStartTime is Timestamp) {
      startTime = rawStartTime.toDate();
    } else if (rawStartTime is String) {
      startTime = DateTime.tryParse(rawStartTime);
    }
    if (startTime != null) {
      final amount = (data['finalAmount'] ?? data['totalAmount'] ?? 0.0) as num;
      games.add(StaffActivityRecord(timestamp: startTime, amount: amount.toDouble()));
    }
  }

  // Query quick sales run by this staff member
  final salesQuery = await firestore
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .collection(FirebaseConstants.salesCollection)
      .where('staffId', isEqualTo: staffId)
      .get();

  final List<StaffActivityRecord> sales = [];
  for (var doc in salesQuery.docs) {
    final data = doc.data();
    final rawTimestamp = data['timestamp'];
    DateTime? timestamp;
    if (rawTimestamp is Timestamp) {
      timestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      timestamp = DateTime.tryParse(rawTimestamp);
    }
    if (timestamp != null) {
      final amount = (data['totalAmount'] ?? data['finalAmount'] ?? 0.0) as num;
      sales.add(StaffActivityRecord(timestamp: timestamp, amount: amount.toDouble()));
    }
  }

  return StaffActivityData(games: games, sales: sales);
});

final staffMonthlyStatsProvider = FutureProvider.family<Map<String, int>, (String, DateTime)>((ref, params) async {
  final staffId = params.$1;
  final month = params.$2;

  final activity = await ref.watch(staffActivityDataProvider(staffId).future);

  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));

  final gamesCount = activity.games.where((g) => !g.timestamp.isBefore(startOfMonth) && !g.timestamp.isAfter(endOfMonth)).length;
  final salesCount = activity.sales.where((s) => !s.timestamp.isBefore(startOfMonth) && !s.timestamp.isAfter(endOfMonth)).length;

  return {'games': gamesCount, 'sales': salesCount};
});

/// Total number of games started all-time by the currently logged-in staff member.
final myStartedGamesCountProvider = FutureProvider<int>((ref) async {
  final staff = ref.watch(currentStaffProvider).value;
  if (staff == null) return 0;
  final activity = await ref.watch(staffActivityDataProvider(staff.id).future);
  return activity.games.length;
});

/// Number of games started today by the currently logged-in staff member.
final myStartedGamesTodayCountProvider = FutureProvider<int>((ref) async {
  final staff = ref.watch(currentStaffProvider).value;
  if (staff == null) return 0;
  final activity = await ref.watch(staffActivityDataProvider(staff.id).future);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  return activity.games.where((g) => !g.timestamp.isBefore(startOfDay) && !g.timestamp.isAfter(endOfDay)).length;
});
