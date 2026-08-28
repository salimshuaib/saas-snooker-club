import 'dart:io';

void main() {
  var file = File('lib/features/games/data/games_repository.dart');
  var content = file.readAsStringSync();

  var startIndex = content.indexOf('Future<void> updateGamePaymentMethods');
  if (startIndex == -1) {
    print('Start not found');
    return;
  }

  var before = content.substring(0, startIndex);

  var replacement = '''Future<void> updateGamePaymentMethods({
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

          if (newMethod == PaymentMethod.credit) {
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: amount,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Game on Table \',
              subtitle: 'T.P. Match Split Liability (Rs\)',
            );
          } else if (oldMethod == PaymentMethod.credit) {
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
        updateMap['paymentMethod'] = null;
        updateMap['paidBy'] = null;
      }
    }
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

        if (newPaymentMethod == PaymentMethod.credit) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: newPaidBy ?? 'Unknown',
            amount: session.grandTotal ?? 0.0,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table \',
          );
        } else if (oldMethod == PaymentMethod.credit) {
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
        } else if (newPaymentMethod == PaymentMethod.credit) {
          updateMap['paymentStatus'] = 'Outstanding';
          updateMap['paidAmount'] = 0.0;
          updateMap['remainingAmount'] = session.grandTotal;
        }
      }
    }

    if (anyChanged) {
      final updatedAuditLogs = [...session.auditLogs, ...newLogs];
      updateMap['auditLogs'] = updatedAuditLogs.map((a) => a.toMap()).toList();
      batch.update(_gamesRef.doc(session.id), updateMap);
      await batch.commit();
    }
  }
}
''';

  file.writeAsStringSync(before + replacement);
  print('Games repo patched correctly');
}
