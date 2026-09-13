import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/credit/data/credit_repository.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

class QuickSalesRepository {
  final FirebaseFirestore _firestore;
  final Ref? _ref;
  final String? clubId;
  QuickSalesRepository(this._firestore, {Ref? ref, this.clubId}) : _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

  String get currentUserName {
    final staff = currentStaff;
    if (staff != null) return staff.name;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerName;
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
      throw Exception('clubId cannot be null for QuickSalesRepository');
    return _firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _quickSalesRef =>
      _clubRef.collection(FirebaseConstants.salesCollection);

  CollectionReference get _inventoryRef =>
      _clubRef.collection(FirebaseConstants.inventoryCollection);

  QuickSale _enrichWithStaff(QuickSale sale, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return sale;

    if (isCreate) {
      return sale.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return sale.copyWith(
        updatedByUserId: staff.id,
        updatedByName: staff.name,
      );
    }
  }

  Stream<List<QuickSale>> watchQuickSales(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _quickSalesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return QuickSale.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList(),
        );
  }

  /// Real-time stream of all quick sales for analytics aggregations.
  Stream<List<QuickSale>> watchAllQuickSales() {
    return _quickSalesRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return QuickSale.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList(),
    );
  }

  /// Real-time stream of quick sales filtered by date range to minimize Firebase reads.
  Stream<List<QuickSale>> watchQuickSalesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _quickSalesRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return QuickSale.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList(),
        );
  }

  /// Paginated fetch for large quick sales collections.
  Future<List<QuickSale>> getQuickSalesPaginated({
    DocumentSnapshot? lastDoc,
    int limit = 50,
  }) async {
    Query query = _quickSalesRef.orderBy('date', descending: true).limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              QuickSale.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  /// Fetch a single quick sale by its ID.
  Future<QuickSale?> getQuickSaleById(String saleId) async {
    final doc = await _quickSalesRef.doc(saleId).get();
    if (!doc.exists) return null;
    return QuickSale.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Creates a quick sale and safely deducts stock from inventory items.
  Future<void> createQuickSale(QuickSale sale) async {
    if (AppConfig.guardWrite('QuickSalesRepository.createQuickSale')) return;
    sale = _enrichWithStaff(sale, true);
    await _firestore.runTransaction((transaction) async {
      // 1. Verify all stock before making changes
      for (final item in sale.items) {
        final docRef = _inventoryRef.doc(item.productId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception(
            'Product ${item.productName} not found in inventory.',
          );
        }

        final data = snapshot.data() as Map<String, dynamic>?;
        final currentStock = data?['currentStock'] as int? ?? 0;
        if (currentStock < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.productName}. Available: $currentStock, Requested: ${item.quantity}',
          );
        }
      }

      // 2. Perform updates
      for (final item in sale.items) {
        final docRef = _inventoryRef.doc(item.productId);
        // Can safely use FieldValue.increment because we verified stock in this transaction block
        transaction.update(docRef, {
          'currentStock': FieldValue.increment(-item.quantity),
          'totalSold': FieldValue.increment(item.quantity),
        });
      }

      // 3. Save Quick Sale
      final saleRef = sale.id.isNotEmpty
          ? _quickSalesRef.doc(sale.id)
          : _quickSalesRef.doc();
      final saleData = sale.toMap();

      transaction.set(saleRef, saleData);

      // 4. Handle Transaction for Player Profile
      if (sale.customerName != null &&
          sale.customerName!.isNotEmpty &&
          sale.paymentMethod == PaymentMethod.credit) {
        final creditRepo = CreditRepository(
          _firestore,
          ref: _ref,
          clubId: clubId,
        );
        await creditRepo.appendCreditToTransaction(
          transaction: transaction,
          customerName: sale.customerName!,
          amount: sale.totalAmount,
          type: CreditTransactionType.quickSale,
          referenceId: saleRef.id, // Guarantee exact Document ID linkage
          title: 'Quick Sale Order',
          subtitle: 'Items: ${sale.items.length}',
          paymentMethod: sale.paymentMethod,
        );
      }
    });
  }

  /// Deletes quick sales, restoring inventory stock and cleaning up associated credit records.
  Future<void> deleteQuickSales(List<QuickSale> sales) async {
    if (AppConfig.guardWrite('QuickSalesRepository.deleteQuickSales')) return;
    if (sales.isEmpty) return;

    // 1. First validate and remove any associated credit transactions (throws if already settled)
    final creditRepo = CreditRepository(_firestore, ref: _ref, clubId: clubId);
    await creditRepo.cascadeDeleteQuickSaleCredits(sales);

    // 2. Perform inventory restoration and document deletion
    await _firestore.runTransaction((transaction) async {
      for (final sale in sales) {
        // Restore stock
        for (final item in sale.items) {
          if (item.productId.isNotEmpty) {
            final docRef = _inventoryRef.doc(item.productId);
            final snap = await transaction.get(docRef);
            if (snap.exists) {
              transaction.update(docRef, {
                'currentStock': FieldValue.increment(item.quantity),
                'totalSold': FieldValue.increment(-item.quantity),
              });
            }
          }
        }
        // Delete sale document
        final saleRef = _quickSalesRef.doc(sale.id);
        transaction.delete(saleRef);

        // Audit Log for Deletion
        final auditRef = _clubRef.collection('audit_logs').doc();
        transaction.set(auditRef, {
          'id': auditRef.id,
          'action': 'Quick Sale Deleted',
          'recordId': sale.id,
          'module': 'QuickSales',
          'userId': currentUserId,
          'userName': currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updateQuickSaleCustomerName({
    required QuickSale sale,
    required String newCustomerName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite(
      'QuickSalesRepository.updateQuickSaleCustomerName',
    ))
      return;
    final oldName = sale.customerName ?? '';
    if (oldName == newCustomerName) return;

    final audit = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_name_${sale.id}',
      editedBy: employeeName,
      timestamp: DateTime.now(),
      field: 'Customer Name',
      previousValue: oldName.isEmpty ? 'None / Walk-in' : oldName,
      newValue: newCustomerName.isEmpty ? 'None / Walk-in' : newCustomerName,
    );

    if (sale.paymentMethod == PaymentMethod.credit &&
        oldName.isNotEmpty &&
        newCustomerName.isNotEmpty) {
      final creditRepo = CreditRepository(
        _firestore,
        ref: _ref,
        clubId: clubId,
      );
      await creditRepo.transferCreditTransaction(
        referenceId: sale.id,
        oldCustomerName: oldName,
        newCustomerName: newCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        title: 'Quick Sale Order',
        subtitle: 'Items: ${sale.items.length}',
      );
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];

    await _quickSalesRef.doc(sale.id).update({
      'customerName': newCustomerName,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    });
  }

  Future<void> updateQuickSalePaymentMethod({
    required QuickSale sale,
    required PaymentMethod newPaymentMethod,
    String? newCustomerName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite(
      'QuickSalesRepository.updateQuickSalePaymentMethod',
    ))
      return;
    final creditRepo = CreditRepository(_firestore, ref: _ref, clubId: clubId);
    final oldMethod = sale.paymentMethod;

    if (oldMethod == newPaymentMethod && sale.customerName == newCustomerName)
      return;

    final audit = AuditLog(
      id: '${sale.id}_pay',
      editedBy: employeeName,
      timestamp: DateTime.now(),
      field: 'Payment Method',
      previousValue: oldMethod.displayName,
      newValue: newPaymentMethod.displayName,
    );

    final batch = _firestore.batch();
    final finalCustomerName = newCustomerName ?? sale.customerName ?? 'Guest';

    if (sale.customerName != null &&
        sale.customerName!.isNotEmpty &&
        oldMethod == PaymentMethod.credit) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id,
        customerName: sale.customerName!,
      );
    }

    if (finalCustomerName.isNotEmpty &&
        finalCustomerName != 'Guest' &&
        newPaymentMethod == PaymentMethod.credit) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: finalCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
        paymentMethod: newPaymentMethod,
      );
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];

    final updateMap = <String, dynamic>{
      'paymentMethod': newPaymentMethod.name,
      'customerName': newPaymentMethod == PaymentMethod.credit
          ? newCustomerName
          : sale.customerName,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    };

    if (newPaymentMethod == PaymentMethod.cash ||
        newPaymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = sale.totalAmount;
      updateMap['remainingAmount'] = 0.0;
    } else if (newPaymentMethod == PaymentMethod.credit) {
      updateMap['paymentStatus'] = 'Outstanding';
      updateMap['paidAmount'] = 0.0;
      updateMap['remainingAmount'] = sale.totalAmount;
    }

    batch.update(_quickSalesRef.doc(sale.id), updateMap);
    await batch.commit();
  }
}
