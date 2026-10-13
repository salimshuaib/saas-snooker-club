import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/happy_hour/data/happy_hour_repository.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';

final happyHourRepositoryProvider = Provider<HappyHourRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return HappyHourRepository(ref: ref, clubId: clubId);
});

final happyHourOffersProvider =
    StreamProvider.autoDispose<List<HappyHourOffer>>((ref) {
  final repo = ref.watch(happyHourRepositoryProvider);
  return repo.watchOffers();
});

/// Returns all currently active and time-eligible offers for a specific table.
final eligibleOffersForTableProvider =
    Provider.autoDispose.family<List<HappyHourOffer>, String>((ref, tableId) {
  final offersAsync = ref.watch(happyHourOffersProvider);
  final offers = offersAsync.value ?? [];
  final now = DateTime.now();

  return offers
      .where((offer) => offer.isCurrentlyEligible(now, tableId))
      .toList();
});
