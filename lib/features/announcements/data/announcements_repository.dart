import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/features/announcements/domain/models/announcement.dart';

class AnnouncementsRepository {
  final FirebaseFirestore _firestore;
  final String? clubId;
  final Ref ref;

  AnnouncementsRepository(this._firestore, {required this.ref, this.clubId});

  CollectionReference get _announcementsRef {
    if (clubId == null) throw Exception("Club ID is not set");
    return _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.announcementsCollection);
  }

  Stream<List<Announcement>> watchAnnouncements() {
    if (clubId == null) return Stream.value([]);
    return _announcementsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Announcement.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> postAnnouncement(Announcement announcement) async {
    if (clubId == null) throw Exception("Club ID is not set");
    final docRef = _announcementsRef.doc();
    final data = announcement.copyWith(id: docRef.id).toMap();
    await docRef.set(data);
  }
}
