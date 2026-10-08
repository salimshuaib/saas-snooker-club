import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Unknown',
      message: map['message'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Announcement copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? createdAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
