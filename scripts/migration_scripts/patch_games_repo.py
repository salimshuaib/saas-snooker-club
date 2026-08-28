import re

with open('lib/features/games/data/games_repository.dart', 'r') as f:
    code = f.read()

target = '''  Future<void> updateGamePaymentMethods({
    required GameSession session,
    PaymentMethod? newPaymentMethod,
    String? newPaidBy,
    Map<String, PaymentMethod>? newPlayerPaymentMethods,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGamePaymentMethods')) return;
    final creditRepo = CreditRepository(_db);
    final List<AuditLog> newLogs = [];

    // Case 1: Split payments (mixed payment methods per player)
    if (newPlayerPaymentMethods != null && newPlayerPaymentMethods.isNotEmpty) {
      final oldPlayerMethods = session.playerPaymentMethods ?? {};
      bool anyChanged = false;
      for (final entry in newPlayerPaymentMethods.entries) {
        final player = entry.key;
        final newMethod = entry.value;
        final oldMethod = oldPlayerMethods[player] ?? session.paymentMethod ?? PaymentMethod.cash;
        if (oldMethod != newMethod) {
          anyChanged = true;
          newLogs.add(AuditLog(
            id: '\_pay_\',
            editedBy: employeeName,
            timestamp: DateTime.now(),
            field: 'Payment Method (\)',
            previousValue: oldMethod.displayName,
            newValue: newMethod.displayName,
          ));

          final amount = session.playerLiabilities?[player] ?? (session.grandTotal ?? 0.0) / newPlayerPaymentMethods.length;

          // Transitioning TO Credit
          if (newMethod == PaymentMethod.credit) {
            await creditRepo.addCreditRecord(
              customerName: player,
              amount: amount,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Game on Table \',
              subtitle: 'T.P. Match Split Liability (?\)',
            );
          }
          // Transitioning FROM Credit
          else if (oldMethod == PaymentMethod.credit) {
            await creditRepo.removeCreditRecord(referenceId: session.id, customerName: player);
          }
        }
      }

      if (anyChanged) {
        final updatedAuditLogs = [...session.auditLogs, ...newLogs];
        await _gamesRef.doc(session.id).update({
          'playerPaymentMethods': newPlayerPaymentMethods.map((k, v) => MapEntry(k, v.name)),
          'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
        });
      }
    }
    // Case 2: Single bill payment change
    else if (newPaymentMethod != null) {
      final oldMethod = session.paymentMethod ?? PaymentMethod.cash;
      bool anyChanged = false;

      if (oldMethod != newPaymentMethod) {
        anyChanged = true;
        newLogs.add(AuditLog(
          id: '\_pay',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Payment Method',
          previousValue: oldMethod.displayName,
          newValue: newPaymentMethod.displayName,
        ));

        // Transitioning TO Credit
        if (newPaymentMethod == PaymentMethod.credit) {
          await creditRepo.addCreditRecord(
            customerName: newPaidBy ?? 'Unknown',
            amount: session.grandTotal ?? 0.0,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table \',
          );
        }
        // Transitioning FROM Credit
        else if (oldMethod == PaymentMethod.credit) {
          await creditRepo.removeCreditRecord(referenceId: session.id, customerName: session.paidBy);
        }
      }

      if (session.paidBy != newPaidBy && newPaymentMethod == PaymentMethod.credit) {
        anyChanged = true;
        newLogs.add(AuditLog(
          id: '\_payer',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Payer Name',
          previousValue: session.paidBy ?? 'None',
          newValue: newPaidBy ?? 'None',
        ));
      }

      if (anyChanged) {
        final updatedAuditLogs = [...session.auditLogs, ...newLogs];
        
        // Ensure paidBy is only saved for credit
        final finalPaidBy = newPaymentMethod == PaymentMethod.credit ? newPaidBy : null;
        
        await _gamesRef.doc(session.id).update({
          'paymentMethod': newPaymentMethod.name,
          'paidBy': finalPaidBy,
          'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
        });
      }
    }
  }'''

replacement = '''  Future<void> updateGamePaymentMethods({
    required GameSession session,
    PaymentMethod? newPaymentMethod,
    String? newPaidBy,
    Map<String, PaymentMethod>? newPlayerPaymentMethods,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGamePaymentMethods')) return;
    final creditRepo = CreditRepository(_db);
    final List<AuditLog> newLogs = [];
    final batch = _db.batch();
    bool anyChanged = false;
    final updateMap = <String, dynamic>{};

    // Case 1: Split payments (mixed payment methods per player)
    if (newPlayerPaymentMethods != null && newPlayerPaymentMethods.isNotEmpty) {
      final oldPlayerMethods = session.playerPaymentMethods ?? {};
      for (final entry in newPlayerPaymentMethods.entries) {
        final player = entry.key;
        final newMethod = entry.value;
        final oldMethod = oldPlayerMethods[player] ?? session.paymentMethod ?? PaymentMethod.cash;
        if (oldMethod != newMethod) {
          anyChanged = true;
          newLogs.add(AuditLog(
            id: '\_pay_\',
            editedBy: employeeName,
            timestamp: DateTime.now(),
            field: 'Payment Method (\)',
            previousValue: oldMethod.displayName,
            newValue: newMethod.displayName,
          ));

          final amount = session.playerLiabilities?[player] ?? (session.grandTotal ?? 0.0) / newPlayerPaymentMethods.length;

          // Transitioning TO Credit
          if (newMethod == PaymentMethod.credit) {
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: amount,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Game on Table \',
              subtitle: 'T.P. Match Split Liability (?\)',
            );
          }
          // Transitioning FROM Credit
          else if (oldMethod == PaymentMethod.credit) {
            await creditRepo.removeCreditFromBatch(
              batch: batch, 
              referenceId: session.id, 
              customerName: player
            );
          }
        }
      }

      if (anyChanged) {
        updateMap['playerPaymentMethods'] = newPlayerPaymentMethods.map((k, v) => MapEntry(k, v.name));
      }
    }
    // Case 2: Single bill payment change
    else if (newPaymentMethod != null) {
      final oldMethod = session.paymentMethod ?? PaymentMethod.cash;

      if (oldMethod != newPaymentMethod) {
        anyChanged = true;
        newLogs.add(AuditLog(
          id: '\_pay',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Payment Method',
          previousValue: oldMethod.displayName,
          newValue: newPaymentMethod.displayName,
        ));

        // Transitioning TO Credit
        if (newPaymentMethod == PaymentMethod.credit) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: newPaidBy ?? 'Unknown',
            amount: session.grandTotal ?? 0.0,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table \',
          );
        }
        // Transitioning FROM Credit
        else if (oldMethod == PaymentMethod.credit) {
          await creditRepo.removeCreditFromBatch(
            batch: batch, 
            referenceId: session.id, 
            customerName: session.paidBy ?? 'Unknown'
          );
        }
      }

      if (session.paidBy != newPaidBy && newPaymentMethod == PaymentMethod.credit) {
        anyChanged = true;
        newLogs.add(AuditLog(
          id: '\_payer',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Payer Name',
          previousValue: session.paidBy ?? 'None',
          newValue: newPaidBy ?? 'None',
        ));
      }

      if (anyChanged) {
        final finalPaidBy = newPaymentMethod == PaymentMethod.credit ? newPaidBy : null;
        updateMap['paymentMethod'] = newPaymentMethod.name;
        updateMap['paidBy'] = finalPaidBy;
        
        if (newPaymentMethod == PaymentMethod.cash || newPaymentMethod == PaymentMethod.upi) {
          updateMap['paymentStatus'] = 'Paid';
          updateMap['paidAmount'] = session.grandTotal;
          updateMap['remainingAmount'] = 0.0;
        }
      }
    }

    if (anyChanged) {
      final updatedAuditLogs = [...session.auditLogs, ...newLogs];
      updateMap['auditLogs'] = updatedAuditLogs.map((a) => a.toMap()).toList();
      batch.update(_gamesRef.doc(session.id), updateMap);
      await batch.commit();
    }
  }'''

code = code.replace(target, replacement)
with open('lib/features/games/data/games_repository.dart', 'w') as f:
    f.write(code)

print("Games repository patched successfully")
