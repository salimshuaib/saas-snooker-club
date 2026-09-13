import os

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

new_method = """  /// Update per-player split payment methods post-completion.
  Future<void> updateGameSplitPaymentMethods({
    required GameSession session,
    required Map<String, PaymentMethod> updatedMethods,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGameSplitPaymentMethods'))
      return;
    if (session.playerPaymentSplits == null) return;

    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    final List<AuditLog> newLogs = [];
    final batch = _db.batch();
    bool anyChanged = false;
    final updateMap = <String, dynamic>{};
    
    // Create new playerPaymentSplits map
    final Map<String, Map<PaymentMethod, double>> newSplits = {};
    double totalPaid = 0.0;
    double totalCredit = 0.0;

    for (final entry in session.playerPaymentSplits!.entries) {
      final playerName = entry.key;
      final oldSplits = entry.value;
      if (oldSplits.isEmpty) continue;
      
      final oldMethod = oldSplits.keys.first;
      final amount = oldSplits.values.first;
      final newMethod = updatedMethods[playerName] ?? oldMethod;
      
      newSplits[playerName] = {newMethod: amount};
      
      if (newMethod == PaymentMethod.cash || newMethod == PaymentMethod.upi) {
        totalPaid += amount;
      } else if (newMethod == PaymentMethod.credit) {
        totalCredit += amount;
      }

      if (oldMethod != newMethod) {
        anyChanged = true;
        newLogs.add(
          AuditLog(
            id: '${session.id}_${playerName}_pay',
            editedBy: currentUserName,
            timestamp: DateTime.now(),
            field: 'Payment ($playerName)',
            previousValue: oldMethod.displayName,
            newValue: newMethod.displayName,
          ),
        );

        if (oldMethod == PaymentMethod.credit) {
          // Remove old credit
          await creditRepo.removeCreditFromBatch(
            batch: batch,
            referenceId: session.id,
            customerName: playerName,
          );
        }
        
        if (newMethod == PaymentMethod.credit) {
          // Add new credit
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: playerName,
            customerId: session.playerIdentities?[playerName],
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            paymentMethod: newMethod,
          );
        }
      }
    }

    if (anyChanged) {
      final updatedAuditLogs = [...session.auditLogs, ...newLogs];
      updateMap['auditLogs'] = updatedAuditLogs.map((a) => a.toMap()).toList();
      
      updateMap['playerPaymentSplits'] = newSplits.map(
        (k, v) => MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
      );
      
      updateMap['paidAmount'] = totalPaid;
      updateMap['remainingAmount'] = totalCredit;
      
      if (totalCredit == 0) {
        updateMap['paymentStatus'] = 'Paid';
      } else if (totalPaid == 0) {
        updateMap['paymentStatus'] = 'Outstanding';
      } else {
        updateMap['paymentStatus'] = 'Partially Paid';
      }
      
      batch.update(_gamesRef.doc(session.id), updateMap);
      await batch.commit();
    }
  }

"""

if 'updateGameSplitPaymentMethods' not in text:
    target = '  Future<void> updateGamePaymentMethods({'
    text = text.replace(target, new_method + target)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("Already exists")

