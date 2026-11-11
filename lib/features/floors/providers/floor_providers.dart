import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/floors/data/floor_repository.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:collection/collection.dart';

final floorRepositoryProvider = Provider<FloorRepository>((ref) {
  final fs = ref.watch(firestoreServiceProvider);
  final clubId = ref.watch(clubIdProvider);
  return FloorRepository(fs, clubId: clubId);
});

final floorsProvider = StreamProvider<List<FloorModel>>((ref) {
  final repo = ref.watch(floorRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchFloors();
});

final hasFloorsProvider = Provider<bool>((ref) {
  final floors = ref.watch(floorsProvider).value;
  return floors != null && floors.isNotEmpty;
});

/// True if club has 2 or more floors.
/// If a club has 0 or 1 floor, floor selectors, floor chips, and "All Floors"
/// options should never be shown anywhere in the app.
final hasMultipleFloorsProvider = Provider<bool>((ref) {
  final floors = ref.watch(floorsProvider).value;
  return floors != null && floors.length > 1;
});

class SelectedFloorIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  String? get state => super.state;

  @override
  set state(String? value) => super.state = value;

  void selectFloor(String? id) => state = id;
}

final selectedFloorIdProvider = NotifierProvider<SelectedFloorIdNotifier, String?>(SelectedFloorIdNotifier.new);

final selectedFloorProvider = Provider<FloorModel?>((ref) {
  final floorId = ref.watch(selectedFloorIdProvider);
  if (floorId == null) return null;
  final floors = ref.watch(floorsProvider).value ?? [];
  return floors.firstWhereOrNull((f) => f.id == floorId);
});
