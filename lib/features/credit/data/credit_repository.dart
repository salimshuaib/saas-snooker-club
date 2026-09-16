import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/core/models/audit_log.dart';

class CreditRepository {
  final FirebaseFirestore _firestore;
  final Ref? _ref;
  final String? clubId;

  CreditRepository(this._firestore, {Ref? ref, this.clubId}) : _ref = ref;

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
    if (clubId == null)
      throw Exception('clubId cannot be null for CreditRepository');
    return _firestore.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _creditsRef =>
      _clubRef.collection(FirebaseConstants.creditsCollection);

  CollectionReference _transactionsRef(String customerId) =>
      _creditsRef.doc(customerId).collection('transactions');

  CollectionReference _paymentsRef(String customerId) =>
      _creditsRef.doc(customerId).collection('payments');

  Stream<List<PlayerProfile>> watchAllCustomers() {
    return _creditsRef
        .orderBy('lastTransactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PlayerProfile.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<CreditTransaction>> watchPendingTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CreditTransaction.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((tx) => tx.status != CreditTransactionStatus.paid)
              .toList(),
        );
  }

  Stream<List<CreditTransaction>> watchAllTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CreditTransaction.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<CreditTransaction>> watchAllTransactionsGlobal(
    DateTime? selectedDate,
  ) {
    Query query = _firestore
        .collectionGroup('transactions')
        .where('clubId', isEqualTo: clubId);
    if (selectedDate != null) {
      final start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }
    query = query.orderBy('date', descending: true);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => CreditTransaction.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Stream<List<PaymentHistory>> watchPaymentHistory(String customerId) {
    return _paymentsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PaymentHistory.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> deletePlayerProfile(String customerId) async {
    if (AppConfig.guardWrite('CreditRepository.deletePlayerProfile')) return;
    final batch = _firestore.batch();

    final transSnap = await _transactionsRef(customerId).get();
    for (final doc in transSnap.docs) {
      batch.delete(doc.reference);
    }

    final paymentsSnap = await _paymentsRef(customerId).get();
    for (final doc in paymentsSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_creditsRef.doc(customerId));
    await batch.commit();
  }

  Future<void> savePlayerProfile(PlayerProfile profile) async {
    if (AppConfig.guardWrite('CreditRepository.savePlayerProfile')) return;
    await _creditsRef
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<PlayerProfile?> getCustomerByName(String name) async {
    final query = await _creditsRef
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return PlayerProfile.fromMap(
      query.docs.first.id,
      query.docs.first.data() as Map<String, dynamic>,
    );
  }

  Stream<List<PaymentHistory>> watchAllPaymentsByDate(String dateStr) {
    // Parse dateStr (yyyy-mm-dd)
    final parts = dateStr.split('-');
    if (parts.length != 3) return const Stream.empty();

    final year = int.tryParse(parts[0]) ?? 2024;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    final startOfDay = DateTime(year, month, day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collectionGroup('payments')
        .where('clubId', isEqualTo: clubId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentHistory.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Appends credit logic within an existing batch
  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    String? customerId,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
    PaymentMethod? paymentMethod,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;

    PlayerProfile? existingCustomer;
    if (customerId != null) {
      final doc = await _creditsRef.doc(customerId).get();
      if (doc.exists) {
        existingCustomer = PlayerProfile.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
    }

    if (existingCustomer == null) {
      existingCustomer = await getCustomerByName(customerName);
    }

    // Duplicate Credit Protection (Phase 3)
    if (!isTransfer && existingCustomer != null) {
      final existingTx = await _transactionsRef(
        existingCustomer.id,
      ).where('referenceId', isEqualTo: referenceId).limit(1).get();
      if (existingTx.docs.isNotEmpty) {
        throw Exception(
          'A credit transaction for this source already exists for this customer.',
        );
      }
    }

    final customerRef = existingCustomer != null
        ? _creditsRef.doc(existingCustomer.id)
        : _creditsRef.doc();

    final isCredit =
        paymentMethod == null || paymentMethod == PaymentMethod.credit;

    if (existingCustomer != null) {
      batch.update(customerRef, {
        if (isCredit) 'outstandingAmount': FieldValue.increment(amount),
        if (isCredit) 'totalPendingTransactions': FieldValue.increment(1),
        'lastTransactionDate': Timestamp.now(),
      });
    } else {
      final newCustomer = PlayerProfile(
        id: customerRef.id,
        name: customerName,
        outstandingAmount: isCredit ? amount : 0.0,
        totalPendingTransactions: isCredit ? 1 : 0,
        lastTransactionDate: DateTime.now(),
      );
      batch.set(customerRef, newCustomer.toMap());
    }

    final transRef = customerRef.collection('transactions').doc();
    final transaction = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      paidAmount: isCredit ? 0.0 : amount,
      remainingAmount: isCredit ? amount : 0.0,
      status: isCredit
          ? CreditTransactionStatus.pending
          : CreditTransactionStatus.paid,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle != null
          ? subtitle +
                (isCredit ? '' : ' - Paid via ${paymentMethod!.displayName}')
          : (isCredit ? null : 'Paid via ${paymentMethod!.displayName}'),
    );
    final data = transaction.toMap();
    data['clubId'] = clubId;
    batch.set(transRef, data);
  }

  /// Appends credit logic within an existing transaction
  Future<void> appendCreditToTransaction({
    required Transaction transaction,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    PaymentMethod? paymentMethod,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToTransaction'))
      return;
    final query = await _creditsRef
        .where('name', isEqualTo: customerName)
        .limit(1)
        .get();
    final existingCustomerDoc = query.docs.isEmpty ? null : query.docs.first;

    final customerRef = existingCustomerDoc != null
        ? _creditsRef.doc(existingCustomerDoc.id)
        : _creditsRef.doc();

    final isCredit =
        paymentMethod == null || paymentMethod == PaymentMethod.credit;

    if (existingCustomerDoc != null) {
      transaction.update(customerRef, {
        if (isCredit) 'outstandingAmount': FieldValue.increment(amount),
        if (isCredit) 'totalPendingTransactions': FieldValue.increment(1),
        'lastTransactionDate': Timestamp.now(),
      });
    } else {
      final newCustomer = PlayerProfile(
        id: customerRef.id,
        name: customerName,
        outstandingAmount: isCredit ? amount : 0.0,
        totalPendingTransactions: isCredit ? 1 : 0,
        lastTransactionDate: DateTime.now(),
      );
      transaction.set(customerRef, newCustomer.toMap());
    }

    final transRef = customerRef.collection('transactions').doc();
    final creditTrans = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      paidAmount: isCredit ? 0.0 : amount,
      remainingAmount: isCredit ? amount : 0.0,
      status: isCredit
          ? CreditTransactionStatus.pending
          : CreditTransactionStatus.paid,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
    );
    final data = creditTrans.toMap();
    data['clubId'] = clubId;
    transaction.set(transRef, data);
  }

  Future<void> processPayment({
    required PlayerProfile customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.processPayment')) return;
    employeeName = currentUserName;
    await _firestore.runTransaction((tx) async {
      if (paymentAmount <= 0) {
        throw Exception("Payment amount must be greater than zero.");
      }
      final customerRef = _creditsRef.doc(customer.id);
      final customerDoc = await tx.get(customerRef);

      if (!customerDoc.exists) throw Exception("Customer not found.");
      final currentOutstanding =
          (customerDoc.data() as Map<String, dynamic>)['outstandingAmount']
              as num;
      final roundedOutstanding = double.parse(
        currentOutstanding.toStringAsFixed(2),
      );
      final roundedPayment = double.parse(paymentAmount.toStringAsFixed(2));

      if (roundedPayment > roundedOutstanding) {
        throw Exception("Payment amount exceeds outstanding balance.");
      }

      final newOutstanding = roundedOutstanding - roundedPayment;

      tx.update(customerRef, {
        'outstandingAmount': newOutstanding,
        'lastPaymentDate': Timestamp.now(),
      });

      // Record Payment History
      final paymentRef = _paymentsRef(customer.id).doc();
      final history = PaymentHistory(
        id: paymentRef.id,
        customerId: customer.id,
        amountPaid: paymentAmount,
        remainingBalance: newOutstanding.toDouble(),
        paymentMethod: paymentMethod,

        employeeName: employeeName,
        date: DateTime.now(),
      );
      final data = history.toMap();
      data['clubId'] = clubId;
      tx.set(paymentRef, data);
    });

    // Always trigger recalculation to properly sync game bills and transaction status
    await recalculateCustomerAccount(customer.id);
  }

  Future<void> mergeCustomers(String sourceId, String targetId) async {
    if (AppConfig.guardWrite('CreditRepository.mergeCustomers')) return;
    await _firestore.runTransaction((tx) async {
      final sourceRef = _creditsRef.doc(sourceId);
      final targetRef = _creditsRef.doc(targetId);

      final sourceDoc = await tx.get(sourceRef);
      final targetDoc = await tx.get(targetRef);

      if (!sourceDoc.exists || !targetDoc.exists) {
        throw Exception("One or both customers not found for merge.");
      }

      final sourceData = sourceDoc.data() as Map<String, dynamic>;
      final targetData = targetDoc.data() as Map<String, dynamic>;

      final sourceOutstanding =
          (sourceData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;
      final targetOutstanding =
          (targetData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;

      final sourcePendingCount =
          (sourceData['totalPendingTransactions'] as num?)?.toInt() ?? 0;
      final targetPendingCount =
          (targetData['totalPendingTransactions'] as num?)?.toInt() ?? 0;

      // Update target customer
      tx.update(targetRef, {
        'outstandingAmount': targetOutstanding + sourceOutstanding,
        'totalPendingTransactions': targetPendingCount + sourcePendingCount,
      });

      // Move transactions
      final sourceTrans = await sourceRef.collection('transactions').get();
      for (var doc in sourceTrans.docs) {
        final newTransRef = targetRef.collection('transactions').doc(doc.id);
        final data = doc.data();
        data['customerId'] = targetId; // Update customer reference
        tx.set(newTransRef, data);
        tx.delete(doc.reference);
      }

      // Move payment history
      final sourcePayments = await sourceRef.collection('payments').get();
      for (var doc in sourcePayments.docs) {
        final newPayRef = targetRef.collection('payments').doc(doc.id);
        final data = doc.data();
        data['customerId'] = targetId;
        tx.set(newPayRef, data);
        tx.delete(doc.reference);
      }

      // Delete source customer
      tx.delete(sourceRef);
    });
  }

  /// Cascade deletes credit transactions for deleted games.
  /// Executes a two-phase process: validates that no associated transaction has been settled,
  /// then deletes pending records and recalculates customer outstanding balances.
  Future<void> cascadeDeleteGameCredits(List<GameSession> sessions) async {
    if (AppConfig.guardWrite('CreditRepository.cascadeDeleteGameCredits'))
      return;
    final List<DocumentSnapshot> transactionsToDelete = [];
    final Set<String> affectedCustomerIds = {};

    // Phase 1: Validation and collection
    for (final session in sessions) {
      final Set<String> customerNames = {};
      if (session.paidBy != null && session.paidBy!.isNotEmpty) {
        customerNames.add(session.paidBy!);
      }
      if (session.playerPaymentSplits != null) {
        for (final entry in session.playerPaymentSplits!.entries) {
          customerNames.add(entry.key);
        }
      }

      if (customerNames.isEmpty) continue;

      List<DocumentSnapshot> matchingDocs = [];
      for (final name in customerNames) {
        final customer = await getCustomerByName(name);
        if (customer != null) {
          final transSnap = await _transactionsRef(
            customer.id,
          ).where('referenceId', isEqualTo: session.id).get();
          matchingDocs.addAll(transSnap.docs);
        }
      }

      // Fallback to collection group search if not found directly under the named customers
      if (matchingDocs.isEmpty) {
        final cgSnap = await _firestore
            .collectionGroup('transactions')
            .where('clubId', isEqualTo: clubId)
            .where('referenceId', isEqualTo: session.id)
            .get();
        matchingDocs.addAll(cgSnap.docs);
      }

      for (final doc in matchingDocs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final statusStr = data['status'] as String? ?? '';

          bool wasCredit = false;
          if (session.playerPaymentSplits != null &&
              session.playerPaymentSplits!.isNotEmpty) {
            final subtitle = data['subtitle'] as String? ?? '';
            if (subtitle.contains('- Paid via')) {
              wasCredit = false;
            } else {
              wasCredit = true;
            }
          } else {
            wasCredit = session.paymentMethod == PaymentMethod.credit;
          }

          if (wasCredit && statusStr == CreditTransactionStatus.paid.name) {
            throw Exception(
              'This game has already been settled through a credit payment. Deleting it will create accounting inconsistencies.',
            );
          }
          transactionsToDelete.add(doc);
          final cid =
              data['customerId'] as String? ?? doc.reference.parent.parent?.id;
          if (cid != null && cid.isNotEmpty) {
            affectedCustomerIds.add(cid);
          }
        }
      }
    }

    // Phase 2: Execution and balance recalculation
    for (final doc in transactionsToDelete) {
      await doc.reference.delete();
    }

    for (final customerId in affectedCustomerIds) {
      await recalculateCustomerAccount(customerId);
    }
  }

  /// Completely recalculates a customer's account balance and transaction statuses.
  Future<void> recalculateCustomerAccount(String customerId) async {
    if (AppConfig.guardWrite('CreditRepository.recalculateCustomerAccount'))
      return;
    final transSnap = await _transactionsRef(
      customerId,
    ).orderBy('date', descending: true).get();
    final paymentsSnap = await _paymentsRef(customerId).get();
    final List<Future<void>> uiUpdates = [];

    if (transSnap.docs.isEmpty && paymentsSnap.docs.isEmpty) {
      await _creditsRef.doc(customerId).delete();
      return;
    }

    double totalCharges = 0.0;
    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalCharges += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    double totalPayments = 0.0;
    for (final doc in paymentsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalPayments += (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
      }
    }

    totalCharges = double.parse(totalCharges.toStringAsFixed(2));
    totalPayments = double.parse(totalPayments.toStringAsFixed(2));

    final double outstanding = math.max(
      0.0,
      double.parse((totalCharges - totalPayments).toStringAsFixed(2)),
    );
    double remainingToCover = outstanding;
    int pendingCount = 0;

    final batch = _firestore.batch();
    final gamesCollection = _clubRef.collection(
      FirebaseConstants.gamesCollection,
    );
    final salesCollection = _clubRef.collection(
      FirebaseConstants.salesCollection,
    );

    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final rawAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final originalAmount = double.parse(rawAmount.toStringAsFixed(2));
        final typeStr = data['type'] as String? ?? '';
        final refId = data['referenceId'] as String? ?? '';

        double txRemaining;
        double txPaid;
        String newStatus;

        if (remainingToCover >= originalAmount) {
          txRemaining = originalAmount;
          txPaid = 0.0;
          newStatus = CreditTransactionStatus.pending.name;
          remainingToCover = math.max(0.0, remainingToCover - originalAmount);
          pendingCount++;
        } else if (remainingToCover > 0) {
          txRemaining = remainingToCover;
          txPaid = originalAmount - remainingToCover;
          newStatus = CreditTransactionStatus.partiallyPaid.name;
          remainingToCover = 0.0;
          pendingCount++;
        } else {
          txRemaining = 0.0;
          txPaid = originalAmount;
          newStatus = CreditTransactionStatus.paid.name;
        }

        batch.update(doc.reference, {
          'status': newStatus,
          'paidAmount': txPaid,
          'remainingAmount': txRemaining,
        });

        if (refId.isNotEmpty) {
          String displayStatus =
              newStatus == CreditTransactionStatus.pending.name
              ? 'Outstanding'
              : newStatus == CreditTransactionStatus.partiallyPaid.name
              ? 'Partially Paid'
              : 'Paid';

          if (typeStr == CreditTransactionType.game.name) {
            uiUpdates.add(
              gamesCollection
                  .doc(refId)
                  .update({
                    'paymentStatus': displayStatus,
                    'paidAmount': txPaid,
                    'remainingAmount': txRemaining,
                  })
                  .catchError((_) {}),
            );
          } else if (typeStr == CreditTransactionType.quickSale.name) {
            uiUpdates.add(
              salesCollection
                  .doc(refId)
                  .update({
                    'paymentStatus': displayStatus,
                    'paidAmount': txPaid,
                    'remainingAmount': txRemaining,
                  })
                  .catchError((_) {}),
            );
          }
        }
      }
    }

    batch.update(_creditsRef.doc(customerId), {
      'outstandingAmount': outstanding,
      'totalPendingTransactions': pendingCount,
    });

    await batch.commit();
  }

  /// Cascade deletes credit transactions for deleted quick sales.
  Future<void> cascadeDeleteQuickSaleCredits(List<QuickSale> sales) async {
    if (AppConfig.guardWrite('CreditRepository.cascadeDeleteQuickSaleCredits'))
      return;
    final List<DocumentSnapshot> transactionsToDelete = [];
    final Set<String> affectedCustomerIds = {};

    for (final sale in sales) {
      if (sale.paymentMethod == PaymentMethod.credit &&
          sale.customerName != null) {
        List<DocumentSnapshot> matchingDocs = [];
        final customer = await getCustomerByName(sale.customerName!);
        if (customer != null) {
          final transSnap = await _transactionsRef(
            customer.id,
          ).where('referenceId', isEqualTo: sale.id).get();
          matchingDocs.addAll(transSnap.docs);
        }

        if (matchingDocs.isEmpty) {
          final cgSnap = await _firestore
              .collectionGroup('transactions')
              .where('clubId', isEqualTo: clubId)
              .where('referenceId', isEqualTo: sale.id)
              .get();
          matchingDocs.addAll(cgSnap.docs);
        }

        for (final doc in matchingDocs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final statusStr = data['status'] as String? ?? '';
            if (statusStr == CreditTransactionStatus.paid.name) {
              throw Exception(
                'This quick sale has already been settled through a credit payment. Deleting it will create accounting inconsistencies.',
              );
            }
            transactionsToDelete.add(doc);
            final cid =
                data['customerId'] as String? ??
                doc.reference.parent.parent?.id;
            if (cid != null && cid.isNotEmpty) {
              affectedCustomerIds.add(cid);
            }
          }
        }
      }
    }

    for (final doc in transactionsToDelete) {
      await doc.reference.delete();
    }

    for (final customerId in affectedCustomerIds) {
      await recalculateCustomerAccount(customerId);
    }
  }

  Future<void> deleteCreditTransactions(
    List<CreditTransaction> transactions,
  ) async {
    if (AppConfig.guardWrite('CreditRepository.deleteCreditTransactions'))
      return;
    final Set<String> affectedCustomerIds = {};
    for (final tx in transactions) {
      if (tx.status == CreditTransactionStatus.paid) {
        throw Exception(
          'Cannot delete transaction "${tx.title}" as it has already been settled through a payment.',
        );
      }
      await _transactionsRef(tx.customerId).doc(tx.id).delete();
      affectedCustomerIds.add(tx.customerId);
    }
    for (final customerId in affectedCustomerIds) {
      await recalculateCustomerAccount(customerId);
    }
  }

  Future<void> deletePayments(List<PaymentHistory> payments) async {
    if (AppConfig.guardWrite('CreditRepository.deletePayments')) return;
    final Set<String> affectedCustomerIds = {};
    for (final pay in payments) {
      await _paymentsRef(pay.customerId).doc(pay.id).delete();
      affectedCustomerIds.add(pay.customerId);
    }
    for (final customerId in affectedCustomerIds) {
      await recalculateCustomerAccount(customerId);
    }
  }

  /// Renames a credit customer and propagates the new name to all linked games and quick sales.
  Future<void> renameCustomerAndPropagate({
    required String customerId,
    required String oldName,
    required String newName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.renameCustomerAndPropagate'))
      return;
    employeeName = currentUserName;
    if (oldName == newName) return;
    final targetExisting = await getCustomerByName(newName);
    if (targetExisting != null && targetExisting.id != customerId) {
      // If target name already belongs to another customer, merge into target
      await mergeCustomers(customerId, targetExisting.id);
      return;
    }

    await _creditsRef.doc(customerId).update({'name': newName});

    final transSnap = await _transactionsRef(customerId).get();
    final gamesCollection = _clubRef.collection(
      FirebaseConstants.gamesCollection,
    );
    final salesCollection = _clubRef.collection(
      FirebaseConstants.salesCollection,
    );

    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final typeStr = data['type'] as String? ?? '';
      final refId = data['referenceId'] as String? ?? '';
      if (refId.isEmpty) continue;

      if (typeStr == CreditTransactionType.game.name) {
        final gameDoc = await gamesCollection.doc(refId).get();
        if (gameDoc.exists && gameDoc.data() != null) {
          final game = GameSession.fromMap(gameDoc.data()!);
          bool changed = false;

          final newPlayers = game.players.map((p) {
            if (p == oldName) {
              changed = true;
              return newName;
            }
            return p;
          }).toList();

          String? newPaidBy = game.paidBy;
          if (newPaidBy == oldName) {
            newPaidBy = newName;
            changed = true;
          }

          String? newWinner = game.winnerId;
          if (newWinner == oldName) {
            newWinner = newName;
            changed = true;
          }

          Map<String, Map<PaymentMethod, double>>? newPaymentSplits;
          if (game.playerPaymentSplits != null) {
            newPaymentSplits = {};
            for (final entry in game.playerPaymentSplits!.entries) {
              final k = entry.key == oldName ? newName : entry.key;
              if (entry.key == oldName) changed = true;
              newPaymentSplits[k] = entry.value;
            }
          }

          Map<String, double>? newLiabilities;
          if (game.playerLiabilities != null) {
            newLiabilities = {};
            for (final entry in game.playerLiabilities!.entries) {
              final k = entry.key == oldName ? newName : entry.key;
              if (entry.key == oldName) changed = true;
              newLiabilities[k] = entry.value;
            }
          }

          if (changed) {
            final audit = AuditLog(
              id: '${DateTime.now().millisecondsSinceEpoch}_$refId',
              editedBy: employeeName,
              timestamp: DateTime.now(),
              field: 'Player/Customer Name (via Credit Rename)',
              previousValue: oldName,
              newValue: newName,
            );
            final updatedAuditLogs = [...game.auditLogs, audit];

            await gamesCollection.doc(refId).update({
              'players': newPlayers,
              if (newPaidBy != null) 'paidBy': newPaidBy,
              if (newWinner != null) 'winnerId': newWinner,
              if (newPaymentSplits != null)
                'playerPaymentSplits': newPaymentSplits.map(
                  (k, v) =>
                      MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
                ),
              if (newLiabilities != null) 'playerLiabilities': newLiabilities,
              'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
            });
          }
        }
      } else if (typeStr == CreditTransactionType.quickSale.name) {
        final saleDoc = await salesCollection.doc(refId).get();
        if (saleDoc.exists && saleDoc.data() != null) {
          final sale = QuickSale.fromMap(saleDoc.id, saleDoc.data()!);
          if (sale.customerName == oldName) {
            final audit = AuditLog(
              id: '${DateTime.now().millisecondsSinceEpoch}_$refId',
              editedBy: employeeName,
              timestamp: DateTime.now(),
              field: 'Customer Name (via Credit Rename)',
              previousValue: oldName,
              newValue: newName,
            );
            final updatedAuditLogs = [...sale.auditLogs, audit];

            await salesCollection.doc(refId).update({
              'customerName': newName,
              'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
            });
          }
        }
      }
    }
  }

  /// Transfers an existing credit record from one customer name to another when names are edited on a transaction.
  Future<void> transferCreditTransaction({
    required String referenceId,
    required String oldCustomerName,
    required String newCustomerName,
    required double amount,
    required CreditTransactionType type,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.transferCreditTransaction'))
      return;
    if (oldCustomerName.isEmpty ||
        newCustomerName.isEmpty ||
        oldCustomerName == newCustomerName)
      return;

    final batch = _firestore.batch();

    await removeCreditFromBatch(
      batch: batch,
      referenceId: referenceId,
      customerName: oldCustomerName,
    );

    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
      isTransfer: true,
    );

    await batch.commit();
  }

  /// Adds a new credit transaction record and triggers account recalculation.
  Future<void> addCreditRecord({
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    String? employeeName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.addCreditRecord')) return;
    if (customerName.isEmpty || amount <= 0) return;

    final existingCustomer = await getCustomerByName(customerName);

    // Duplicate Credit Protection (Phase 3)
    if (existingCustomer != null) {
      final existingTx = await _transactionsRef(
        existingCustomer.id,
      ).where('referenceId', isEqualTo: referenceId).limit(1).get();
      if (existingTx.docs.isNotEmpty) {
        throw Exception(
          'A credit transaction for this source already exists for this customer.',
        );
      }
    }
    final customerRef = existingCustomer != null
        ? _creditsRef.doc(existingCustomer.id)
        : _creditsRef.doc();

    if (existingCustomer == null) {
      final newCustomer = PlayerProfile(
        id: customerRef.id,
        name: customerName,
        outstandingAmount: 0.0,
        totalPendingTransactions: 0,
        lastTransactionDate: DateTime.now(),
      );
      await customerRef.set(newCustomer.toMap());
    }

    final transRef = customerRef.collection('transactions').doc();
    final tx = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      paidAmount: 0.0,
      remainingAmount: amount,
      status: CreditTransactionStatus.pending,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
      employeeName: employeeName,
    );
    await transRef.set(tx.toMap());
    await recalculateCustomerAccount(customerRef.id);
  }

  /// Removes an existing credit transaction by referenceId and triggers account recalculation.
  /// Appends credit removal logic to a batch
  Future<void> removeCreditFromBatch({
    required WriteBatch batch,
    required String referenceId,
    required String customerName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditFromBatch')) return;
    final customer = await getCustomerByName(customerName);
    if (customer == null) return;

    final transSnap = await _transactionsRef(
      customer.id,
    ).where('referenceId', isEqualTo: referenceId).get();
    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isCredit =
          data['paymentMethod'] == null || data['paymentMethod'] == 'credit';

      if (isCredit) {
        final statusStr = data['status'] as String? ?? '';
        if (statusStr == CreditTransactionStatus.paid.name ||
            statusStr == CreditTransactionStatus.partiallyPaid.name) {
          throw Exception(
            'Cannot convert or remove credit for this transaction as it has already received a payment.',
          );
        }
      }

      final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      batch.delete(doc.reference);

      if (isCredit) {
        batch.update(_creditsRef.doc(customer.id), {
          'outstandingAmount': FieldValue.increment(-originalAmount),
          'totalPendingTransactions': FieldValue.increment(-1),
        });
      }
    }
  }

  Future<void> removeCreditRecord({
    required String referenceId,
    String? customerName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditRecord')) return;
    final Set<String> affectedCustomerIds = {};
    List<DocumentSnapshot> matchingDocs = [];

    if (customerName != null && customerName.isNotEmpty) {
      final customer = await getCustomerByName(customerName);
      if (customer != null) {
        final transSnap = await _transactionsRef(
          customer.id,
        ).where('referenceId', isEqualTo: referenceId).get();
        matchingDocs.addAll(transSnap.docs);
      }
    }

    if (matchingDocs.isEmpty) {
      final cgSnap = await _firestore
          .collectionGroup('transactions')
          .where('clubId', isEqualTo: clubId)
          .where('referenceId', isEqualTo: referenceId)
          .get();
      matchingDocs.addAll(cgSnap.docs);
    }

    for (final doc in matchingDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final statusStr = data['status'] as String? ?? '';
        if (statusStr == CreditTransactionStatus.paid.name) {
          throw Exception(
            'Cannot remove credit for this transaction as it has already been settled via payment.',
          );
        }
        final cid =
            data['customerId'] as String? ?? doc.reference.parent.parent?.id;
        if (cid != null) affectedCustomerIds.add(cid);
      }
      await doc.reference.delete();
    }

    for (final cid in affectedCustomerIds) {
      await recalculateCustomerAccount(cid);
    }
  }
}
