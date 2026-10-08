import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceLog {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String dateString; // YYYY-MM-DD
  final bool autoCheckedOut;
  final bool editedByOwner;

  const AttendanceLog({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.checkInTime,
    this.checkOutTime,
    required this.dateString,
    this.autoCheckedOut = false,
    this.editedByOwner = false,
  });

  factory AttendanceLog.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceLog(
      id: id,
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkOutTime: (map['checkOutTime'] as Timestamp?)?.toDate(),
      dateString: map['dateString'] ?? '',
      autoCheckedOut: map['autoCheckedOut'] ?? false,
      editedByOwner: map['editedByOwner'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'dateString': dateString,
      'autoCheckedOut': autoCheckedOut,
      'editedByOwner': editedByOwner,
    };
  }

  AttendanceLog copyWith({
    String? id,
    String? staffId,
    String? staffName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool clearCheckOutTime = false,
    String? dateString,
    bool? autoCheckedOut,
    bool? editedByOwner,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: clearCheckOutTime ? null : (checkOutTime ?? this.checkOutTime),
      dateString: dateString ?? this.dateString,
      autoCheckedOut: autoCheckedOut ?? this.autoCheckedOut,
      editedByOwner: editedByOwner ?? this.editedByOwner,
    );
  }

  static String generateDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
