import os

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

methods = '''
  Future<void> markAsPendingBill(
    GameSession session, {
    required String customerId,
    required String customerName,
  }) async {
    AppConfig.guardWrite('GamesRepository.markAsPendingBill');
    final staff = _enrichWithStaff({});
    final now = DateTime.now();
    
    final updateMap = {
      ...staff,
      'status': TableStatus.pendingBill.name,
      'paymentStatus': 'Pending',
      'pendingBillCustomerId': customerId,
      'pendingBillCustomerName': customerName,
      'markedPendingAt': now.toIso8601String(),
      'markedPendingByUserId': currentUserId,
      'markedPendingByName': currentUserName,
      
      'endTime': session.endTime?.toIso8601String() ?? now.toIso8601String(),
      'gameCharge': session.gameCharge,
      'baseGameCharge': session.baseGameCharge,
      'overtimeMinutes': session.overtimeMinutes,
      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'manualGamesTotal': session.manualGamesTotal,
      'grandTotal': session.grandTotal,
      'roundedAmount': session.roundedAmount,
      'finalAmount': session.finalAmount,
      'discountAmount': session.discountAmount,
      'discountPercent': session.discountPercent,
      'playerPaymentSplits': session.playerPaymentSplits?.map(
            (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv)))),
      'playerLiabilities': session.playerLiabilities,
    };
    
    final auditLog = AuditLog(
      id: const Uuid().v4(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Marked Pending',
      previousValue: 'Running',
      newValue: customerName,
    );
    final logMap = auditLog.toMap();
    
    final batch = _firestore.batch();
    
    final gameRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);
        
    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });
    
    // Clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _firestore
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {'activeGameId': null});
    }
    
    // Deduct inventory stock for orders
    if (session.orders.isNotEmpty) {
      for (final order in session.orders) {
        if (order.productId != null) {
          final productRef = _firestore
              .collection(FirebaseConstants.clubsCollection)
              .doc(clubId)
              .collection('inventory')
              .doc(order.productId);
              
          batch.update(productRef, {
            'currentStock': FieldValue.increment(-order.quantity),
            'totalSold': FieldValue.increment(order.quantity),
          });
        }
      }
    }
    
    // Global audit log
    final globalLogRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();
        
    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Pending Bill',
    });
    
    await batch.commit();
  }

  Future<void> settlePendingBill(GameSession session, {
    required PaymentMethod? paymentMethod,
    required String? paidBy,
    required Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
  }) async {
    AppConfig.guardWrite('GamesRepository.settlePendingBill');
    
    final doc = await _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id)
        .get();
        
    if (!doc.exists || doc.data()?['status'] != TableStatus.pendingBill.name) {
      throw Exception('This bill is no longer pending or has already been settled.');
    }
    
    final staff = _enrichWithStaff({});
    final now = DateTime.now();
    
    final isSplit = playerPaymentSplits != null && playerPaymentSplits.isNotEmpty;
    final totalAmount = session.roundedAmount ?? session.finalAmount ?? session.grandTotal ?? 0.0;
    
    String newPaymentStatus = 'Paid';
    double paidAmount = totalAmount;
    double remainingAmount = 0.0;
    
    final batch = _firestore.batch();
    
    if (isSplit) {
      double totalCredit = 0.0;
      double totalPaid = 0.0;

      for (var player in playerPaymentSplits.keys) {
        final splits = playerPaymentSplits[player]!;
        for (var entry in splits.entries) {
          if (entry.key == PaymentMethod.credit && entry.value > 0) {
            totalCredit += entry.value;
            final creditRepo = _ref.read(creditRepositoryProvider);
            creditRepo.appendCreditToBatch(
              batch: batch,
              clubId: clubId,
              customerId: player, 
              amount: entry.value,
              referenceId: session.id,
              type: CreditTransactionType.game,
              description: 'Split Payment for ',
              staffId: currentUserId ?? 'Unknown',
              staffName: currentUserName ?? 'Unknown',
            );
          } else if (entry.value > 0) {
            totalPaid += entry.value;
          }
        }
      }

      paidAmount = totalPaid;
      remainingAmount = totalCredit;

      if (totalCredit >= totalAmount - 0.01) {
        newPaymentStatus = 'Outstanding';
      } else if (totalCredit > 0) {
        newPaymentStatus = 'Partially Paid';
      }
    } else if (paymentMethod == PaymentMethod.credit) {
      newPaymentStatus = 'Outstanding';
      paidAmount = 0.0;
      remainingAmount = totalAmount;
      
      final customerName = paidBy ?? session.pendingBillCustomerName;
      
      final creditRepo = _ref.read(creditRepositoryProvider);
      creditRepo.appendCreditToBatch(
        batch: batch,
        clubId: clubId,
        customerId: customerName ?? 'Unknown',
        amount: totalAmount,
        referenceId: session.id,
        type: CreditTransactionType.game,
        description: 'Payment for ',
        staffId: currentUserId ?? 'Unknown',
        staffName: currentUserName ?? 'Unknown',
      );
    }
    
    final updateMap = {
      ...staff,
      'status': TableStatus.available.name,
      'paymentStatus': newPaymentStatus,
      'paymentMethod': (!isSplit) ? paymentMethod?.name : null,
      'paidBy': paidBy,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'endTime': now.toIso8601String(),
      if (isSplit) 'playerPaymentSplits': playerPaymentSplits.map(
            (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv)))),
    };
    
    final auditLog = AuditLog(
      id: const Uuid().v4(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Pending Bill Settled',
      previousValue: 'Pending',
      newValue: '₹$totalAmount',
    );
    final logMap = auditLog.toMap();
    
    final gameRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);
        
    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });
    
    final globalLogRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();
        
    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Settled Pending Bill',
    });
    
    await batch.commit();
  }

  Future<void> cancelPendingBill(String gameId, GameSession session) async {
    AppConfig.guardWrite('GamesRepository.cancelPendingBill');
    
    final staff = _enrichWithStaff({});
    final now = DateTime.now();
    
    final updateMap = {
      ...staff,
      'status': TableStatus.cancelled.name,
      'isCancelled': true,
      'paymentStatus': 'Cancelled',
      'finalAmount': 0.0,
      'grandTotal': 0.0,
      'gameCharge': 0.0,
      'baseGameCharge': 0.0,
      'overtimeCharge': 0.0,
      'ordersTotal': 0.0,
      'manualGamesTotal': 0.0,
      'roundedAmount': 0.0,
    };
    
    final auditLog = AuditLog(
      id: const Uuid().v4(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Pending Bill Cancelled',
      previousValue: 'Pending',
      newValue: 'Cancelled',
    );
    final logMap = auditLog.toMap();
    
    final batch = _firestore.batch();
    
    final gameRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(gameId);
        
    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });
    
    if (session.orders.isNotEmpty) {
      for (final order in session.orders) {
        if (order.productId != null) {
          final productRef = _firestore
              .collection(FirebaseConstants.clubsCollection)
              .doc(clubId)
              .collection('inventory')
              .doc(order.productId);
              
          batch.update(productRef, {
            'currentStock': FieldValue.increment(order.quantity),
            'totalSold': FieldValue.increment(-order.quantity),
          });
        }
      }
    }
    
    final globalLogRef = _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();
        
    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Cancel Pending Bill',
    });
    
    await batch.commit();
  }

  Stream<List<GameSession>> watchPendingBills() {
    return _firestore
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .where('status', isEqualTo: TableStatus.pendingBill.name)
        .orderBy('markedPendingAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameSession.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
'''

target = '''    });
  }
}

Stream<List<OtherGameResource>> watchOtherGames() {'''

replacement = '''    });
  }
''' + methods + '''
}

Stream<List<OtherGameResource>> watchOtherGames() {'''

if 'watchPendingBills' not in content:
    content = content.replace(target, replacement)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
print('games_repository fixed')
