import 'package:cloud_firestore/cloud_firestore.dart';

class FloorModel {
  final String id;
  final String name;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FloorModel({
    required this.id,
    required this.name,
    this.order = 0,
    required this.createdAt,
    this.updatedAt,
  });

  FloorModel copyWith({
    String? id,
    String? name,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FloorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'order': order,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory FloorModel.fromMap(Map<String, dynamic> map) => FloorModel(
    id: map['id'] as String,
    name: map['name'] as String,
    order: (map['order'] as num?)?.toInt() ?? 0,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FloorModel &&
        other.id == id &&
        other.name == name &&
        other.order == order &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        order.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
