import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Immutable record of a modification made to a completed transaction.
class AuditLog {
  final String id;
  final String editedBy;
  final DateTime timestamp;
  final String field;
  final String previousValue;
  final String newValue;

  const AuditLog({
    required this.id,
    required this.editedBy,
    required this.timestamp,
    required this.field,
    required this.previousValue,
    required this.newValue,
  });

  String get formattedDate {
    final fmt = DateFormat('d MMM yyyy, hh:mm a');
    return fmt.format(timestamp);
  }

  AuditLog copyWith({
    String? id,
    String? editedBy,
    DateTime? timestamp,
    String? field,
    String? previousValue,
    String? newValue,
  }) {
    return AuditLog(
      id: id ?? this.id,
      editedBy: editedBy ?? this.editedBy,
      timestamp: timestamp ?? this.timestamp,
      field: field ?? this.field,
      previousValue: previousValue ?? this.previousValue,
      newValue: newValue ?? this.newValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'editedBy': editedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'field': field,
      'previousValue': previousValue,
      'newValue': newValue,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    return AuditLog(
      id:
          map['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: map['editedBy'] as String? ?? 'Admin',
      timestamp: parseDate(map['timestamp']),
      field: map['field'] as String? ?? 'Unknown',
      previousValue: map['previousValue'] as String? ?? '-',
      newValue: map['newValue'] as String? ?? '-',
    );
  }
}
