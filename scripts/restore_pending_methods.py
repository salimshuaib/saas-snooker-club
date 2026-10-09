import sys
import re

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

methods = '''
  Future<void> markAsPendingBill(
    GameSession session, {
    required String customerId,
    required String customerName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.markAsPendingBill')) return;
    
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    
    final batch = _db.batch();
    
    final updateMap = {
      'updatedByUserId': staffId,
      'updatedByName': staffName,
      'status': TableStatus.pendingBill.name,
      'paymentStatus': 'Pending',
      'pendingBillCustomerId': customerId,
      'pendingBillCustomerName': customerName,
      'markedPendingAt': now.toIso8601String(),
      'markedPendingByUserId': currentUserId,
      'markedPendingByName': currentUserName,
    };
    
    final auditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_pending',
      editedBy: staffName,
      timestamp: now,
      field: 'Marked as Pending',
      previousValue: '-',
      newValue: customerName,
    );
    final logMap = auditLog.toMap();
    
    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);
        
    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });
    
    final globalLogRef = _db
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

  Future<void> markAsPendingBillWithSplits(
    GameSession session,
    List<Map<String, String>> players,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.markAsPendingBillWithSplits')) return;
    
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    
    final batch = _db.batch();
    
    final totalAmount = session.finalAmount ?? session.grandTotal ?? 0.0;
    final splitAmount = players.isEmpty ? totalAmount : totalAmount / players.length;
    
    for (int i = 0; i < players.length; i++) {
      final pId = players[i]['id']!;
      final pName = players[i]['name']!;
      
      final splitSession = session.copyWith(
        id: i == 0 ? session.id : '${session.id}_split_$i',
        status: TableStatus.pendingBill,
        paymentStatus: 'Pending',
        pendingBillCustomerId: pId,
        pendingBillCustomerName: pName,
        markedPendingAt: now,
        markedPendingByUserId: staffId,
        markedPendingByName: staffName,
        grandTotal: splitAmount,
        finalAmount: splitAmount,
        gameCharge: (session.gameCharge ?? 0.0) / players.length,
        ordersTotal: (session.ordersTotal ?? 0.0) / players.length,
        manualGamesTotal: (session.manualGamesTotal ?? 0.0) / players.length,
        discountAmount: (session.discountAmount ?? 0.0) / players.length,
      );
      
      final gameRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(splitSession.id);
          
      if (i == 0) {
        batch.update(gameRef, splitSession.toMap());
      } else {
        batch.set(gameRef, splitSession.toMap());
      }
      
      final auditLog = AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_pending_$i',
        editedBy: staffName,
        timestamp: now,
        field: 'Marked as Pending (Split)',
        previousValue: '-',
        newValue: pName,
      );
      final logMap = auditLog.toMap();
      
      batch.update(gameRef, {
        'auditLogs': FieldValue.arrayUnion([logMap]),
      });
      
      final globalLogRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection('audit_logs')
          .doc();
          
      batch.set(globalLogRef, {
        ...logMap,
        'recordId': splitSession.id,
        'recordType': 'Game',
        'action': 'Pending Bill',
      });
    }
    
    await batch.commit();
  }

  Future<void> settlePendingBill(GameSession session, {
    required PaymentMethod? paymentMethod,
    required String? paidBy,
    required Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.settlePendingBill')) return;
    
    final doc = await _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id)
        .get();
        
    if (!doc.exists || doc.data()?['status'] != TableStatus.pendingBill.name) {
      throw Exception('This bill is no longer pending or has already been settled.');
    }
    
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    
    final isSplit = playerPaymentSplits != null && playerPaymentSplits.isNotEmpty;
    final totalAmount = session.roundedAmount ?? session.finalAmount ?? session.grandTotal ?? 0.0;
    
    String newPaymentStatus = 'Paid';
    double paidAmount = totalAmount;
    double remainingAmount = 0.0;
    
    final batch = _db.batch();
    
    if (isSplit) {
      double totalCredit = 0.0;
      double totalPaid = 0.0;

      for (var player in playerPaymentSplits.keys) {
        final splits = playerPaymentSplits[player]!;
        for (var entry in splits.entries) {
          if (entry.key == PaymentMethod.credit && entry.value > 0) {
            totalCredit += entry.value;
            final creditRepo = _ref!.read(creditRepositoryProvider);
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: entry.value,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Pending Bill - ${session.tableName}',
              paymentMethod: PaymentMethod.credit,
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
      
      final creditRepo = _ref!.read(creditRepositoryProvider);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: customerName ?? 'Unknown',
        amount: totalAmount,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Pending Bill - ${session.tableName}',
        paymentMethod: PaymentMethod.credit,
      );
    }
    
    final updateMap = {
      'updatedByUserId': staffId,
      'updatedByName': staffName,
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
      id: '${DateTime.now().millisecondsSinceEpoch}_settled',
      editedBy: staffName,
      timestamp: now,
      field: 'Pending Bill Settled',
      previousValue: 'Pending',
      newValue: '₹$totalAmount',
    );
    final logMap = auditLog.toMap();
    
    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);
        
    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });
    
    final globalLogRef = _db
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
    if (AppConfig.guardWrite('GamesRepository.cancelPendingBill')) return;
    
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    
    final updateMap = {
      'updatedByUserId': staffId,
      'updatedByName': staffName,
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
      id: '${DateTime.now().millisecondsSinceEpoch}_cancelled',
      editedBy: staffName,
      timestamp: now,
      field: 'Pending Bill Cancelled',
      previousValue: 'Pending',
      newValue: 'Cancelled',
    );
    final logMap = auditLog.toMap();
    
    final batch = _db.batch();
    
    final gameRef = _db
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
          final productRef = _db
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
    
    final globalLogRef = _db
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
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .where('status', isEqualTo: TableStatus.pendingBill.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return GameSession.fromMap(data);
          })
          .toList();
    });
  }
'''

if 'markAsPendingBill' not in content:
    idx = content.rfind('}')
    content = content[:idx] + methods + content[idx:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Restored all missing pending bill methods to games_repository!')
else:
    print('Methods already present!')
