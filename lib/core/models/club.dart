import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  final String clubName;
  final String appName;
  final String ownerUid;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String? logoUrl;
  final String themeColor;
  final bool isActive;
  final String? suspensionMessage;
  final double? subscriptionPrice;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? lastPaymentDate;
  final DateTime createdAt;
  final bool isOnboarded;

  const Club({
    required this.id,
    required this.clubName,
    required this.appName,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    this.logoUrl,
    required this.themeColor,
    required this.isActive,
    this.suspensionMessage,
    this.subscriptionPrice,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.lastPaymentDate,
    required this.createdAt,
    required this.isOnboarded,
  });

  factory Club.fromMap(Map<String, dynamic> map, String id) {
    return Club(
      id: id,
      clubName: map['clubName'] as String? ?? 'Unknown Club',
      appName: map['appName'] as String? ?? 'S&B Manager',
      ownerUid: map['ownerUid'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerEmail: map['ownerEmail'] as String? ?? '',
      ownerPhone: map['ownerPhone'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      themeColor: map['themeColor'] as String? ?? '#1B5E20',
      isActive: map['isActive'] as bool? ?? true,
      suspensionMessage: map['suspensionMessage'] as String?,
      subscriptionPrice: (map['subscriptionPrice'] as num?)?.toDouble(),
      subscriptionStartDate: (map['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (map['subscriptionEndDate'] as Timestamp?)?.toDate(),
      lastPaymentDate: (map['lastPaymentDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnboarded: map['isOnboarded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubName': clubName,
      'appName': appName,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'logoUrl': logoUrl,
      'themeColor': themeColor,
      'isActive': isActive,
      'suspensionMessage': suspensionMessage,
      'subscriptionPrice': subscriptionPrice,
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnboarded': isOnboarded,
    };
  }
}
