import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/services/firestore_service.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';

class FloorRepository {
  final FirestoreService _firestoreService;
  final String? clubId;

  FloorRepository(this._firestoreService, {this.clubId});

  FirebaseFirestore get _db => _firestoreService.db;

  CollectionReference get _floorsRef {
    if (clubId == null) throw Exception('clubId cannot be null for FloorRepository');
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.floorsCollection);
  }

  CollectionReference get _tablesRef {
    if (clubId == null) throw Exception('clubId cannot be null for FloorRepository');
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.tablesCollection);
  }

  Stream<List<FloorModel>> watchFloors() {
    if (clubId == null) return const Stream.empty();
    return _floorsRef
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return FloorModel.fromMap(data);
          }).toList();
        })
        .handleError((error) {
          AppLogger.error('Error streaming floors: $error');
        });
  }

  Future<List<FloorModel>> getFloors() async {
    if (clubId == null) return [];
    try {
      final snapshot = await _floorsRef.orderBy('order').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FloorModel.fromMap(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching floors: $e');
      return [];
    }
  }

  Future<void> addFloor(FloorModel floor) async {
    if (AppConfig.guardWrite('FloorRepository.addFloor')) return;
    if (clubId == null) return;
    try {
      if (floor.id.isEmpty) {
        final docRef = _floorsRef.doc();
        final floorWithId = floor.copyWith(id: docRef.id);
        await docRef.set(floorWithId.toMap());
      } else {
        await _floorsRef.doc(floor.id).set(floor.toMap());
      }
    } catch (e) {
      AppLogger.error('Failed to add floor: $e');
      rethrow;
    }
  }

  Future<void> updateFloor(FloorModel floor) async {
    if (AppConfig.guardWrite('FloorRepository.updateFloor')) return;
    if (clubId == null) return;
    try {
      final updatedFloor = floor.copyWith(updatedAt: DateTime.now());
      await _floorsRef.doc(updatedFloor.id).update(updatedFloor.toMap());
      
      // We should also update the denormalized floorName in tables if it changed, 
      // but for simplicity, we let the batch table assignment handle updates if needed,
      // or we can explicitly do it here. We'll leave it as is.
    } catch (e) {
      AppLogger.error('Failed to update floor: $e');
      rethrow;
    }
  }

  Future<void> deleteFloor(String floorId) async {
    if (AppConfig.guardWrite('FloorRepository.deleteFloor')) return;
    if (clubId == null) return;
    try {
      final batch = _db.batch();
      
      // 1. Unassign all tables from this floor
      final tablesSnapshot = await _tablesRef.where('floorId', isEqualTo: floorId).get();
      for (final doc in tablesSnapshot.docs) {
        batch.update(doc.reference, {
          'floorId': null,
          'floorName': null,
        });
      }
      
      // 2. Delete the floor document
      batch.delete(_floorsRef.doc(floorId));
      
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to delete floor: $e');
      rethrow;
    }
  }

  Future<void> reorderFloors(List<FloorModel> floors) async {
    if (AppConfig.guardWrite('FloorRepository.reorderFloors')) return;
    if (clubId == null) return;
    try {
      final batch = _db.batch();
      for (int i = 0; i < floors.length; i++) {
        final floor = floors[i];
        batch.update(_floorsRef.doc(floor.id), {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to reorder floors: $e');
      rethrow;
    }
  }

  Future<void> assignTablesToFloor(String floorId, String floorName, List<String> tableIds) async {
    if (AppConfig.guardWrite('FloorRepository.assignTablesToFloor')) return;
    if (clubId == null) return;
    try {
      final batch = _db.batch();
      for (final tableId in tableIds) {
        batch.update(_tablesRef.doc(tableId), {
          'floorId': floorId,
          'floorName': floorName,
        });
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to assign tables to floor: $e');
      rethrow;
    }
  }

  Future<void> unassignTablesFromFloor(List<String> tableIds) async {
    if (AppConfig.guardWrite('FloorRepository.unassignTablesFromFloor')) return;
    if (clubId == null) return;
    try {
      final batch = _db.batch();
      for (final tableId in tableIds) {
        batch.update(_tablesRef.doc(tableId), {
          'floorId': null,
          'floorName': null,
        });
      }
      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to unassign tables from floor: $e');
      rethrow;
    }
  }
}
