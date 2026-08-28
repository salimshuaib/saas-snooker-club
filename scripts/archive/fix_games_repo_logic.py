import os

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

old_logic = """    if (session.paymentMethod == PaymentMethod.cash ||
        session.paymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = session.grandTotal;
      updateMap['remainingAmount'] = 0.0;
    }

    if (session.isManualEntry) {
      // Manual entry: write full session without touching the active table status
      final fullMap = session.toMap();
      fullMap['status'] = TableStatus.available.name;
      if (session.paymentMethod == PaymentMethod.cash ||
          session.paymentMethod == PaymentMethod.upi) {
        fullMap['paymentStatus'] = 'Paid';
        fullMap['paidAmount'] = session.grandTotal;
        fullMap['remainingAmount'] = 0.0;
      }
      batch.set(_gamesRef.doc(session.id), fullMap);
    } else {
      batch.update(_gamesRef.doc(session.id), updateMap);
      batch.update(_tablesRef.doc(session.tableId), {
        'status': TableStatus.available.name,
        'activeGameId': FieldValue.delete(),
      });
    }

    // Append credit records directly here
    if (session.paymentMethod == PaymentMethod.split) {
      final creditRepo = CreditRepository(_db);
      if (session.playerPaymentMethods != null) {
        for (final entry in session.playerPaymentMethods!.entries) {
          if (entry.value == PaymentMethod.credit) {
            final customerName = entry.key;
            final amount = session.playerLiabilities?[customerName] ?? 0.0;
            if (amount > 0) {
              await creditRepo.appendCreditToBatch(
                batch: batch,
                customerName: customerName,
                customerId: session.playerIdentities != null ? session.playerIdentities![customerName] : null,
                amount: amount,
                type: CreditTransactionType.game,
                referenceId: session.id,
                title: 'Game on Table ${session.tableName}',
                subtitle:
                    'T.P. Match Split Liability (₹${amount.toStringAsFixed(2)})',
              );
            }
          }
        }
      }
    } else if (session.paymentMethod == PaymentMethod.credit &&
        session.paidBy != null) {
      final creditRepo = CreditRepository(_db);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        customerId: session.playerIdentities != null ? session.playerIdentities![session.paidBy!] : null,
        amount: session.grandTotal ?? 0.0,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: ₹${session.grandTotal?.toStringAsFixed(2)}',
      );
    }"""

new_logic = """    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;

    if (session.paymentMethod == PaymentMethod.cash ||
        session.paymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = amountToPay;
      updateMap['remainingAmount'] = 0.0;
    }

    if (session.isManualEntry) {
      // Manual entry: write full session without touching the active table status
      final fullMap = session.toMap();
      fullMap['status'] = TableStatus.available.name;
      if (session.paymentMethod == PaymentMethod.cash ||
          session.paymentMethod == PaymentMethod.upi) {
        fullMap['paymentStatus'] = 'Paid';
        fullMap['paidAmount'] = amountToPay;
        fullMap['remainingAmount'] = 0.0;
      }
      batch.set(_gamesRef.doc(session.id), fullMap);
    } else {
      batch.update(_gamesRef.doc(session.id), updateMap);
      batch.update(_tablesRef.doc(session.tableId), {
        'status': TableStatus.available.name,
        'activeGameId': FieldValue.delete(),
      });
    }

    // Append transaction records directly here (handles ALL methods now)
    final creditRepo = CreditRepository(_db);
    
    if (session.paymentMethod == PaymentMethod.split && session.playerPaymentMethods != null) {
      for (final entry in session.playerPaymentMethods!.entries) {
        final customerName = entry.key;
        final paymentMethod = entry.value;
        final amount = session.playerLiabilities?[customerName] ?? 0.0;
        
        if (amount > 0) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: customerName,
            customerId: session.playerIdentities != null ? session.playerIdentities![customerName] : null,
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Match (₹${amount.toStringAsFixed(2)})',
            paymentMethod: paymentMethod,
          );
        }
      }
    } else if (session.paymentMethod != null && session.paymentMethod != PaymentMethod.split && session.paidBy != null) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        customerId: session.playerIdentities != null ? session.playerIdentities![session.paidBy!] : null,
        amount: amountToPay,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: ₹${amountToPay.toStringAsFixed(2)}',
        paymentMethod: session.paymentMethod!,
      );
    }"""

c = c.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
