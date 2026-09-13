import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore;
  final Ref? _ref;
  final String? clubId;

  InventoryRepository(this._firestore, {Ref? ref, this.clubId}) : _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

  String get currentUserName {
    try {
      final club = _ref?.read(clubProfileProvider).value;
      final staff = currentStaff;
      if (staff != null) {
        if (staff.role == StaffRole.owner && club != null && club.ownerName.isNotEmpty) {
          return club.ownerName;
        }
        if (staff.name.isNotEmpty && staff.name != 'Admin' && staff.name != 'Club Owner') {
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
    if (clubId == null)
      throw Exception('clubId cannot be null for InventoryRepository');
    return _firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _inventoryRef =>
      _clubRef.collection(FirebaseConstants.inventoryCollection);

  CollectionReference get _stockHistoryRef =>
      _clubRef.collection('stock_history');

  Stream<List<InventoryItem>> watchInventory() {
    return _inventoryRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return InventoryItem.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList(),
        );
  }

  Stream<List<StockHistory>> watchStockHistory(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _stockHistoryRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return StockHistory.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList(),
        );
  }

  Future<void> addProduct(InventoryItem item) async {
    if (AppConfig.guardWrite('InventoryRepository.addProduct')) return;
    final docRef = _inventoryRef.doc();
    final data = item.toMap();
    await docRef.set(data);
  }

  Future<void> updateProduct(InventoryItem item) async {
    if (AppConfig.guardWrite('InventoryRepository.updateProduct')) return;
    await _inventoryRef.doc(item.id).update(item.toMap());
  }

  Future<void> disableProduct(String id) async {
    if (AppConfig.guardWrite('InventoryRepository.disableProduct')) return;
    await _inventoryRef.doc(id).update({'isActive': false});
  }

  Future<void> addStock({
    required InventoryItem item,
    required int quantityAdded,
    required double purchasePrice,
    String employeeName = 'Admin',
    String? notes,
  }) async {
    if (AppConfig.guardWrite('InventoryRepository.addStock')) return;
    final batch = _firestore.batch();

    // 1. Update InventoryItem
    final updatedStock = item.currentStock + quantityAdded;
    final updatedPurchased = item.totalPurchased + quantityAdded;

    batch.update(_inventoryRef.doc(item.id), {
      'currentStock': updatedStock,
      'totalPurchased': updatedPurchased,
      'purchasePrice': purchasePrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add Stock History
    final historyRef = _stockHistoryRef.doc();
    final history = StockHistory(
      id: historyRef.id,
      productId: item.id,
      productName: item.name,
      quantityAdded: quantityAdded,
      purchasePrice: purchasePrice,
      employeeName: currentUserName,
      notes: notes,
      date: DateTime.now(),
    );
    batch.set(historyRef, history.toMap());

    await batch.commit();
  }

  /// Seeds initial product catalogue with dummy stock if they do not already exist in Firestore.
  Future<void> seedInitialInventory(List<InventoryItem> initialItems) async {
    if (AppConfig.guardWrite('InventoryRepository.seedInitialInventory'))
      return;
    try {
      final snapshot = await _inventoryRef.get();
      final existingNames = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return (data?['name'] as String? ?? '').trim().toLowerCase();
      }).toSet();

      final batch = _firestore.batch();
      int addedCount = 0;
      for (final item in initialItems) {
        if (!existingNames.contains(item.name.trim().toLowerCase())) {
          final docRef = _inventoryRef.doc();
          batch.set(docRef, item.toMap());
          addedCount++;
        }
      }
      if (addedCount > 0) {
        await batch.commit();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error seeding initial inventory: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
