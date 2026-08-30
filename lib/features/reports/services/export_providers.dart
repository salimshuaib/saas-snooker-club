import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

final reportCreditsStreamProvider = StreamProvider<List<CreditTransaction>>((ref) {
  final range = ref.watch(analyticsTimeRangeProvider);
  final clubId = ref.watch(clubIdProvider);
  
  if (clubId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collectionGroup('transactions')
      .where('clubId', isEqualTo: clubId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
      .snapshots()
      .map((snap) {
        return snap.docs.map((doc) => CreditTransaction.fromMap(doc.id, doc.data())).toList();
      });
});

