import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole { owner, manager, staff }

enum StaffAccessLevel {
  full,
  limited;

  String get displayName => this == StaffAccessLevel.full ? 'Full Access' : 'Limited Access';
}

class StaffMember {
  final String id; // Firebase Auth UID
  final String name;
  final String email;
  final StaffRole role;
  final StaffAccessLevel accessLevel;
  final bool isActive;
  final bool isCheckedIn;
  final DateTime? lastCheckInTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.accessLevel = StaffAccessLevel.full,
    this.isActive = true,
    this.isCheckedIn = false,
    this.lastCheckInTime,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLimitedAccess => role != StaffRole.owner && accessLevel == StaffAccessLevel.limited;
  bool get hasFullAccess => !isLimitedAccess;
  bool get canViewFinancials => !isLimitedAccess;
  bool get canExportReports => !isLimitedAccess;

  factory StaffMember.fromMap(Map<String, dynamic> map, String id) {
    return StaffMember(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      role: StaffRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['role'] as String?)?.toLowerCase(),
        orElse: () => StaffRole.staff,
      ),
      accessLevel: StaffAccessLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['accessLevel'] as String?)?.toLowerCase(),
        orElse: () => StaffAccessLevel.full,
      ),
      isActive: map['isActive'] as bool? ?? true,
      isCheckedIn: map['isCheckedIn'] as bool? ?? false,
      lastCheckInTime: (map['lastCheckInTime'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'accessLevel': accessLevel.name,
      'isActive': isActive,
      'isCheckedIn': isCheckedIn,
      if (lastCheckInTime != null) 'lastCheckInTime': Timestamp.fromDate(lastCheckInTime!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  StaffMember copyWith({
    String? name,
    String? email,
    StaffRole? role,
    StaffAccessLevel? accessLevel,
    bool? isActive,
    bool? isCheckedIn,
    DateTime? lastCheckInTime,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      accessLevel: accessLevel ?? this.accessLevel,
      isActive: isActive ?? this.isActive,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
