import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/announcements/data/announcements_repository.dart';
import 'package:snooker_club/features/announcements/domain/models/announcement.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return AnnouncementsRepository(
    FirebaseFirestore.instance,
    ref: ref,
    clubId: clubId,
  );
});

final announcementsProvider = StreamProvider.autoDispose<List<Announcement>>((ref) {
  final repo = ref.watch(announcementsRepositoryProvider);
  return repo.watchAnnouncements();
});
