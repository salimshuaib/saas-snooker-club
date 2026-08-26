import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole { owner, manager, staff }

class StaffMember {
  final String id; // Firebase Auth UID
  final String name;
  final String email;
  final StaffRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffMember.fromMap(Map<String, dynamic> map, String id) {
    return StaffMember(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      role: StaffRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['role'] as String?)?.toLowerCase(),
        orElse: () => StaffRole.staff,
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  StaffMember copyWith({
    String? name,
    String? email,
    StaffRole? role,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
