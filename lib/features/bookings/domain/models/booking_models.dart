import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

class BookingModel {
  final String id;
  final String clubId;
  final String tableId;
  final String tableName;
  final TableType tableType;

  final String customerName;
  final String customerPhone;
  final int? playerCount;
  final String? notes;

  final DateTime bookingDate;
  final DateTime startTime;
  final DateTime endTime;

  final BookingStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String? managedBy;

  const BookingModel({
    required this.id,
    required this.clubId,
    required this.tableId,
    required this.tableName,
    required this.tableType,
    required this.customerName,
    required this.customerPhone,
    this.playerCount,
    this.notes,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.managedBy,
  });

  BookingModel copyWith({
    String? id,
    String? clubId,
    String? tableId,
    String? tableName,
    TableType? tableType,
    String? customerName,
    String? customerPhone,
    int? playerCount,
    String? notes,
    DateTime? bookingDate,
    DateTime? startTime,
    DateTime? endTime,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? managedBy,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      tableType: tableType ?? this.tableType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      playerCount: playerCount ?? this.playerCount,
      notes: notes ?? this.notes,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      managedBy: managedBy ?? this.managedBy,
    );
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      clubId: map['clubId'] as String? ?? '',
      tableId: map['tableId'] as String? ?? '',
      tableName: map['tableName'] as String? ?? 'Unknown Resource',
      tableType: TableType.values.firstWhere(
        (e) => e.name == (map['tableType'] as String?),
        orElse: () => TableType.snooker,
      ),
      customerName: map['customerName'] as String? ?? 'Unknown Customer',
      customerPhone: map['customerPhone'] as String? ?? '',
      playerCount: map['playerCount'] as int?,
      notes: map['notes'] as String?,
      bookingDate:
          (map['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      managedBy: map['managedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'tableId': tableId,
      'tableName': tableName,
      'tableType': tableType.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'playerCount': playerCount,
      'notes': notes,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'managedBy': managedBy,
    };
  }
}
