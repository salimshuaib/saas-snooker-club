import 'package:cloud_firestore/cloud_firestore.dart';

class HappyHourOffer {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final String dailyStartTime; // e.g. "14:00" (24-hour format)
  final String dailyEndTime; // e.g. "18:00" or "02:00" for overnight
  final bool isOvernightSchedule;
  final Map<String, double> gameOffers; // tableId -> promotional price
  final DateTime createdAt;
  final String createdByUserId;
  final String createdByName;
  final DateTime? updatedAt;
  final String? updatedByUserId;
  final String? updatedByName;

  const HappyHourOffer({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    required this.dailyStartTime,
    required this.dailyEndTime,
    this.isOvernightSchedule = false,
    this.gameOffers = const {},
    required this.createdAt,
    required this.createdByUserId,
    required this.createdByName,
    this.updatedAt,
    this.updatedByUserId,
    this.updatedByName,
  });

  /// Checks if a given datetime falls within the scheduled date range and daily time window.
  bool isTimeEligible(DateTime time) {
    if (!isActive) return false;

    // Check date boundaries (inclusive of start and end days)
    final checkDate = DateTime(time.year, time.month, time.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);

    if (checkDate.isBefore(startDay) || checkDate.isAfter(endDay)) {
      return false;
    }

    // Parse daily start and end times
    final startParts = dailyStartTime.split(':');
    final endParts = dailyEndTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;

    final startMinutes = (int.tryParse(startParts[0]) ?? 0) * 60 +
        (int.tryParse(startParts[1]) ?? 0);
    final endMinutes = (int.tryParse(endParts[0]) ?? 0) * 60 +
        (int.tryParse(endParts[1]) ?? 0);
    final currentMinutes = time.hour * 60 + time.minute;

    if (isOvernightSchedule || endMinutes < startMinutes) {
      // Overnight window: e.g. 22:00 (1320) to 02:00 (120)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Normal same-day window: e.g. 14:00 (840) to 18:00 (1080)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Checks if this offer applies to the specific table at the current moment.
  bool isCurrentlyEligible(DateTime now, String tableId) {
    if (!isActive) return false;
    if (!gameOffers.containsKey(tableId)) return false;
    return isTimeEligible(now);
  }

  HappyHourOffer copyWith({
    String? id,
    String? name,
    String? code,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? dailyStartTime,
    String? dailyEndTime,
    bool? isOvernightSchedule,
    Map<String, double>? gameOffers,
    DateTime? createdAt,
    String? createdByUserId,
    String? createdByName,
    DateTime? updatedAt,
    String? updatedByUserId,
    String? updatedByName,
  }) {
    return HappyHourOffer(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyStartTime: dailyStartTime ?? this.dailyStartTime,
      dailyEndTime: dailyEndTime ?? this.dailyEndTime,
      isOvernightSchedule: isOvernightSchedule ?? this.isOvernightSchedule,
      gameOffers: gameOffers ?? this.gameOffers,
      createdAt: createdAt ?? this.createdAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code.trim().toUpperCase(),
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'dailyStartTime': dailyStartTime,
      'dailyEndTime': dailyEndTime,
      'isOvernightSchedule': isOvernightSchedule,
      'gameOffers': gameOffers,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedByUserId': updatedByUserId,
      'updatedByName': updatedByName,
    };
  }

  factory HappyHourOffer.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawGameOffers = map['gameOffers'];
    final Map<String, double> offers = {};
    if (rawGameOffers is Map) {
      rawGameOffers.forEach((k, v) {
        offers[k.toString()] = (v as num).toDouble();
      });
    }

    final startTime = map['dailyStartTime'] as String? ?? '00:00';
    final endTime = map['dailyEndTime'] as String? ?? '23:59';
    final isOvernight = (map['isOvernightSchedule'] as bool?) ?? false;

    return HappyHourOffer(
      id: (docId ?? map['id'] ?? '') as String,
      name: map['name'] as String? ?? '',
      code: (map['code'] as String? ?? '').trim().toUpperCase(),
      isActive: map['isActive'] as bool? ?? true,
      startDate: parseDateTime(map['startDate']),
      endDate: parseDateTime(map['endDate']),
      dailyStartTime: startTime,
      dailyEndTime: endTime,
      isOvernightSchedule: isOvernight,
      gameOffers: offers,
      createdAt: parseDateTime(map['createdAt']),
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      updatedAt: map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null,
      updatedByUserId: map['updatedByUserId'] as String?,
      updatedByName: map['updatedByName'] as String?,
    );
  }
}
