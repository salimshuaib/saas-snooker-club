import 'dart:io';

void main() {
  final file = File('lib/features/games/data/games_repository.dart');
  var content = file.readAsStringSync();
  
  final idx = content.indexOf('Future<void> settlePendingBill(');
  
  final newMethod = '''
  Future<void> settlePendingBillsCombined(
    List<GameSession> bills, {
    required PaymentMethod? paymentMethod,
    required String? paidBy,
    required String customerName,
    required double roundedTotal,
    required Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
  }) async {
    AppConfig.guardWrite('GamesRepository.settlePendingBillsCombined');

    if (bills.isEmpty) return;

    final batch = _db.batch();
    final now = DateTime.now();

    // 1. Calculate merged values
    double totalGameCharge = 0;
    double totalBaseGameCharge = 0;
    double totalOvertimeCharge = 0;
    double totalOrdersTotal = 0;
    double totalDiscountAmount = 0;
    double totalGrandTotal = 0;
    int totalActiveSeconds = 0;
    
    DateTime? earliestStartTime;
    List<String> tableNames = [];
    List<GameOrder> allOrders = [];
    List<ManualGameCharge> allManualGames = [];
    List<AuditLog> allAuditLogs = [];
    List<GameRound> allRounds = [];

    for (final bill in bills) {
      totalGameCharge += (bill.gameCharge ?? 0);
      totalBaseGameCharge += (bill.baseGameCharge ?? 0);
      totalOvertimeCharge += (bill.overtimeCharge ?? 0);
      totalOrdersTotal += (bill.ordersTotal ?? 0);
      totalDiscountAmount += (bill.discountAmount ?? 0);
      totalGrandTotal += (bill.grandTotal ?? 0);
      totalActiveSeconds += bill.activeSeconds;

      if (earliestStartTime == null || (bill.startTime != null && bill.startTime!.isBefore(earliestStartTime))) {
        earliestStartTime = bill.startTime;
      }
      
      if (!tableNames.contains(bill.tableName)) {
        tableNames.add(bill.tableName);
      }
      
      allOrders.addAll(bill.orders);
      allManualGames.addAll(bill.manualGameCharges);
      allAuditLogs.addAll(bill.auditLogs);
      if (bill.rounds != null) {
        allRounds.addAll(bill.rounds!);
      }

      // Delete the original pending bill
      final originalRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(bill.id);
      batch.delete(originalRef);
    }

    final isSplit = playerPaymentSplits != null && playerPaymentSplits.isNotEmpty;
    String newPaymentStatus = 'Paid';
    double paidAmount = roundedTotal;
    double remainingAmount = 0.0;
    final consolidatedId = '\${DateTime.now().millisecondsSinceEpoch}_combined';

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
              referenceId: consolidatedId,
              title: 'Consolidated Pending Bill',
              subtitle: 'Tables: \${tableNames.join(", ")}',
              paymentMethod: PaymentMethod.credit,
            );
          } else if (entry.value > 0) {
            totalPaid += entry.value;
          }
        }
      }

      paidAmount = totalPaid;
      remainingAmount = totalCredit;

      if (totalCredit >= roundedTotal - 0.01) {
        newPaymentStatus = 'Outstanding';
      } else if (totalCredit > 0) {
        newPaymentStatus = 'Partially Paid';
      }
    } else if (paymentMethod == PaymentMethod.credit) {
      newPaymentStatus = 'Outstanding';
      paidAmount = 0.0;
      remainingAmount = roundedTotal;
      
      final creditRepo = _ref!.read(creditRepositoryProvider);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: customerName,
        amount: roundedTotal,
        type: CreditTransactionType.game,
        referenceId: consolidatedId,
        title: 'Consolidated Pending Bill',
        subtitle: 'Tables: \${tableNames.join(", ")}',
        paymentMethod: PaymentMethod.credit,
      );
    }

    // Add consolidation audit log
    final summaryLog = AuditLog(
      id: '\${DateTime.now().millisecondsSinceEpoch}_consolidate',
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Consolidated Pending Bills',
      previousValue: '\${bills.length} bills',
      newValue: '₹\$roundedTotal',
    );
    allAuditLogs.add(summaryLog);

    // Enrich with staff explicitly
    final staffName = currentUserName ?? 'Unknown';
    final staffId = currentUserId ?? 'Unknown';

    final updateMap = {
      'id': consolidatedId,
      'clubId': clubId,
      'tableId': bills.first.tableId, // Just use first for reference
      'tableName': tableNames.join(", "),
      'tableType': bills.first.tableType.name,
      'gameType': bills.first.gameType.name,
      'billingType': bills.first.billingType.name,
      'status': TableStatus.available.name,
      'paymentStatus': newPaymentStatus,
      'paymentMethod': (!isSplit) ? paymentMethod?.name : null,
      'paidBy': paidBy ?? customerName,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'startTime': earliestStartTime?.toIso8601String() ?? now.toIso8601String(),
      'endTime': now.toIso8601String(),
      'activeSeconds': totalActiveSeconds,
      'players': bills.first.players,
      
      'gameCharge': totalGameCharge,
      'baseGameCharge': totalBaseGameCharge,
      'overtimeCharge': totalOvertimeCharge,
      'ordersTotal': totalOrdersTotal,
      'discountAmount': totalDiscountAmount,
      'grandTotal': totalGrandTotal,
      'roundedAmount': roundedTotal,
      'finalAmount': roundedTotal,
      
      'orders': allOrders.map((o) => o.toMap()).toList(),
      'manualGameCharges': allManualGames.map((m) => m.toMap()).toList(),
      'rounds': allRounds.map((r) => r.toMap()).toList(),
      'auditLogs': allAuditLogs.map((l) => l.toMap()).toList(),
      
      'createdByUserId': staffId,
      'createdByName': staffName,
      'updatedByUserId': staffId,
      'updatedByName': staffName,
      'date': DateFormat('yyyy-MM-dd').format(now),
      
      if (isSplit) 'playerPaymentSplits': playerPaymentSplits.map(
            (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv)))),
    };

    final newGameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(consolidatedId);
        
    batch.set(newGameRef, updateMap);

    // Global audit log
    final globalLogRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();
        
    batch.set(globalLogRef, {
      ...summaryLog.toMap(),
      'recordId': consolidatedId,
      'recordType': 'Game',
      'action': 'Consolidated Pending Bills',
    });

    await batch.commit();
  }

''';
  
  content = content.substring(0, idx) + newMethod + content.substring(idx);
  file.writeAsStringSync(content);
}
