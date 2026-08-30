import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/models/club.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';

// 1. User Club Mapping
class UserClub {
  final String clubId;
  final String role;
  const UserClub({required this.clubId, required this.role});
}

final userClubProvider = StreamProvider<UserClub?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.userClubsCollection)
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return UserClub(
      clubId: data['clubId'] as String,
      role: data['role'] as String? ?? 'staff',
    );
  });
});

final clubIdProvider = Provider<String?>((ref) {
  final userClub = ref.watch(userClubProvider).value;
  return userClub?.clubId;
});

final clubProfileProvider = StreamProvider<Club?>((ref) {
  final clubId = ref.watch(clubIdProvider);
  if (clubId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.clubsCollection)
      .doc(clubId)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return Club.fromMap(doc.data()!, doc.id);
  });
});

final isClubActiveProvider = Provider<bool>((ref) {
  final clubProfile = ref.watch(clubProfileProvider).value;
  return clubProfile?.isActive ?? false;
});

// Platform Config
class PlatformConfig {
  final double subscriptionPrice;
  final String currency;
  final String? paymentQrUrl;
  final String? upiId;
  final String? supportPhone;
  final String? supportEmail;

  const PlatformConfig({
    this.subscriptionPrice = 2999,
    this.currency = 'INR',
    this.paymentQrUrl,
    this.upiId,
    this.supportPhone,
    this.supportEmail,
  });

  factory PlatformConfig.fromMap(Map<String, dynamic> map) {
    return PlatformConfig(
      subscriptionPrice: (map['subscriptionPrice'] as num?)?.toDouble() ?? 2999,
      currency: map['currency'] as String? ?? 'INR',
      paymentQrUrl: map['paymentQrUrl'] as String?,
      upiId: map['upiId'] as String?,
      supportPhone: map['supportPhone'] as String?,
      supportEmail: map['supportEmail'] as String?,
    );
  }
}

final platformConfigProvider = StreamProvider<PlatformConfig>((ref) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.platformCollection)
      .doc('config')
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return Stream.value(const PlatformConfig());
    return PlatformConfig.fromMap(doc.data()!);
  });
});

