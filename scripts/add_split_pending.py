import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_method = '''  Future<void> markAsPendingBillWithSplits(
    GameSession session,
    List<Map<String, String>> players,
  ) async {
    AppConfig.guardWrite('GamesRepository.markAsPendingBillWithSplits');
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    final batch = _db.batch();

    final splitCount = players.length;
    if (splitCount == 0) return;

    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);
        
    // Delete the original session so it doesn't show up in history
    batch.delete(gameRef);

    // Also clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {'activeGameId': null});
    }

    // Now loop and create new split sessions
    for (int i = 0; i < splitCount; i++) {
      final pId = players[i]['id']!;
      final pName = players[i]['name']!;
      
      final splitId = '${session.id}_split_$i';
      
      final auditLog = AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_split_$i',
        editedBy: staffName,
        timestamp: now,
        field: 'Marked Pending (Split)',
        previousValue: 'Running',
        newValue: '1 of $splitCount assigned to $pName',
      );

      final splitSession = session.copyWith(
        id: splitId,
        status: TableStatus.pendingBill,
        paymentStatus: 'Pending',
        pendingBillCustomerId: pId,
        pendingBillCustomerName: pName,
        markedPendingAt: now,
        markedPendingByUserId: staffId,
        markedPendingByName: staffName,
        endTime: session.endTime ?? now,
        
        // Divide all charges by the number of splits
        gameCharge: (session.gameCharge ?? 0) / splitCount,
        baseGameCharge: (session.baseGameCharge ?? 0) / splitCount,
        overtimeCharge: (session.overtimeCharge ?? 0) / splitCount,
        ordersTotal: (session.ordersTotal ?? 0) / splitCount,
        discountAmount: (session.discountAmount ?? 0) / splitCount,
        grandTotal: (session.grandTotal ?? 0) / splitCount,
        roundedAmount: (session.roundedAmount ?? 0) / splitCount,
        finalAmount: (session.finalAmount ?? 0) / splitCount,
        customPrice: (session.gameCharge ?? 0) / splitCount, // Set custom price so recalculations don't break it
        isMinimumBillEnabled: false,
        auditLogs: [...session.auditLogs, auditLog],
      );

      final newGameRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(splitId);
          
      batch.set(newGameRef, _enrichWithStaff(splitSession, true).toMap());
    }

    await batch.commit();
  }

'''

# Add this method after markAsPendingBill
idx = content.find('  Future<void> settlePendingBill')
if idx != -1:
    content = content[:idx] + new_method + content[idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Added markAsPendingBillWithSplits to GamesRepository')
