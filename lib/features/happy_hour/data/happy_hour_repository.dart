import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class HappyHourRepository {
  final FirebaseFirestore _db;
  final Ref? _ref;
  final String? clubId;

  HappyHourRepository({
    FirebaseFirestore? db,
    Ref? ref,
    this.clubId,
  })  : _db = db ?? FirebaseFirestore.instance,
        _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

  String get currentUserName {
    try {
      final club = _ref?.read(clubProfileProvider).value;
      final staff = currentStaff;
      if (staff != null) {
        if (staff.role == StaffRole.owner &&
            club != null &&
            club.ownerName.isNotEmpty) {
          return club.ownerName;
        }
        if (staff.name.isNotEmpty &&
            staff.name != 'Admin' &&
            staff.name != 'Club Owner') {
          return staff.name;
        }
      }
      if (club != null && club.ownerName.isNotEmpty) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }

  String get currentUserId {
    final staff = currentStaff;
    if (staff != null) return staff.id;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerUid;
    } catch (_) {}
    return 'Unknown';
  }

  DocumentReference get _clubRef {
    if (clubId == null) {
      throw Exception('clubId cannot be null for HappyHourRepository');
    }
    return _db.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _offersRef =>
      _clubRef.collection(FirebaseConstants.happyHoursCollection);

  /// Real-time stream of all Happy Hour offers for this club.
  Stream<List<HappyHourOffer>> watchOffers() {
    if (clubId == null) return Stream.value([]);
    return _offersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return HappyHourOffer.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Fetch all Happy Hour offers one-time.
  Future<List<HappyHourOffer>> getOffers() async {
    if (clubId == null) return [];
    final snapshot =
        await _offersRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return HappyHourOffer.fromMap(data, doc.id);
    }).toList();
  }

  /// Check if an offer code already exists (case-insensitive).
  Future<bool> isCodeDuplicate(String code, {String? excludeOfferId}) async {
    final cleanCode = code.trim().toUpperCase();
    final snapshot = await _offersRef.get();
    for (final doc in snapshot.docs) {
      if (excludeOfferId != null && doc.id == excludeOfferId) continue;
      final data = doc.data() as Map<String, dynamic>;
      final existingCode = (data['code'] as String? ?? '').trim().toUpperCase();
      if (existingCode == cleanCode) {
        return true;
      }
    }
    return false;
  }

  /// Create a new Happy Hour offer.
  Future<void> createOffer(HappyHourOffer offer) async {
    if (AppConfig.guardWrite('HappyHourRepository.createOffer')) return;

    final isDuplicate = await isCodeDuplicate(offer.code);
    if (isDuplicate) {
      throw Exception('Offer code "${offer.code.toUpperCase()}" is already in use.');
    }

    final docRef = _offersRef.doc();
    final toSave = offer.copyWith(
      id: docRef.id,
      createdByUserId: currentUserId,
      createdByName: currentUserName,
      createdAt: DateTime.now(),
    );

    await docRef.set(toSave.toMap());
  }

  /// Update an existing offer.
  Future<void> updateOffer(HappyHourOffer offer) async {
    if (AppConfig.guardWrite('HappyHourRepository.updateOffer')) return;

    final isDuplicate =
        await isCodeDuplicate(offer.code, excludeOfferId: offer.id);
    if (isDuplicate) {
      throw Exception('Offer code "${offer.code.toUpperCase()}" is already in use.');
    }

    final toSave = offer.copyWith(
      updatedByUserId: currentUserId,
      updatedByName: currentUserName,
      updatedAt: DateTime.now(),
    );

    await _offersRef.doc(offer.id).update(toSave.toMap());
  }

  /// Quickly toggle the active state of an offer.
  Future<void> toggleOfferActive(String offerId, bool isActive) async {
    if (AppConfig.guardWrite('HappyHourRepository.toggleOfferActive')) return;

    await _offersRef.doc(offerId).update({
      'isActive': isActive,
      'updatedByUserId': currentUserId,
      'updatedByName': currentUserName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete an offer.
  Future<void> deleteOffer(String offerId) async {
    if (AppConfig.guardWrite('HappyHourRepository.deleteOffer')) return;

    await _offersRef.doc(offerId).delete();
  }

  /// Find all offers currently eligible for a table.
  Future<List<HappyHourOffer>> getEligibleOffersForTable(
    String tableId, {
    DateTime? checkTime,
  }) async {
    final now = checkTime ?? DateTime.now();
    final allOffers = await getOffers();
    return allOffers
        .where((offer) => offer.isCurrentlyEligible(now, tableId))
        .toList();
  }
}
