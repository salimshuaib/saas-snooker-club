import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/services/firestore_service.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/providers/app_providers.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final clubId = ref.watch(clubIdProvider);
  return BookingsRepository(firestoreService, clubId: clubId);
});

final dateBookingsStreamProvider =
    StreamProvider.family<List<BookingModel>, DateTime>((ref, date) {
      final repo = ref.watch(bookingsRepositoryProvider);
      return repo.watchBookingsForDate(date);
    });

class BookingsRepository {
  final FirestoreService _firestoreService;
  final String? clubId;

  BookingsRepository(this._firestoreService, {this.clubId});

  FirebaseFirestore get _db => _firestoreService.db;

  CollectionReference get _bookingsRef {
    if (clubId == null)
      throw Exception('clubId cannot be null for BookingsRepository');
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.bookingsCollection);
  }

  /// Watch all bookings for a specific date (from 00:00:00 to 23:59:59)
  Stream<List<BookingModel>> watchBookingsForDate(DateTime date) {
    if (clubId == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return _bookingsRef
        .where(
          'bookingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('bookingDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('bookingDate')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
          return list;
        });
  }

  /// Watch all unconfirmed bookings
  Stream<List<BookingModel>> watchUnconfirmedBookings() {
    if (clubId == null) return Stream.value([]);

    return _bookingsRef
        .where('status', isEqualTo: BookingStatus.unconfirmed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> createBooking(BookingModel booking) async {
    await _bookingsRef.add(booking.toMap());
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _bookingsRef.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
