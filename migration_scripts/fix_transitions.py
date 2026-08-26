import re

# Fix GamesRepository
with open('lib/features/games/data/games_repository.dart', 'r') as f:
    games_code = f.read()

games_pattern = re.compile(r'  Future<void> updateGamePaymentMethods\(\{.*?\}\s*else\s*if\s*\(newPaymentMethod != null\)\s*\{.*?\}\s*\}', re.DOTALL)

games_replacement = '''  Future<void> updateGamePaymentMethods({
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
  }'''

games_new_code = games_pattern.sub(games_replacement, games_code)

if games_new_code == games_code:
    print("WARNING: GamesRepository not modified.")
else:
    with open('lib/features/games/data/games_repository.dart', 'w') as f:
        f.write(games_new_code)
    print("GamesRepository patched.")

# Fix QuickSalesRepository
with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'r') as f:
    sales_code = f.read()

sales_pattern = re.compile(r'  Future<void> updateQuickSalePaymentMethod\(\{.*?\}\s*await _salesRef\.doc\(sale\.id\)\.update\(\{.*?' + r'\}\);\s*\}', re.DOTALL)

sales_replacement = '''  Future<void> updateQuickSalePaymentMethod({
    required QuickSale sale,
    required PaymentMethod newPaymentMethod,
    String? newCustomerName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('QuickSalesRepository.updateQuickSalePaymentMethod')) return;
    final creditRepo = CreditRepository(_firestore);
    final oldMethod = sale.paymentMethod;
    
    if (oldMethod == newPaymentMethod && sale.customerName == newCustomerName) return;

    final audit = AuditLog(
      id: '\_pay',
      editedBy: employeeName,
      timestamp: DateTime.now(),
      field: 'Payment Method',
      previousValue: oldMethod.displayName,
      newValue: newPaymentMethod.displayName,
    );
    
    final batch = _firestore.batch();
    final finalCustomerName = newCustomerName ?? sale.customerName ?? 'Guest';

    if (newPaymentMethod == PaymentMethod.credit && oldMethod != PaymentMethod.credit) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: finalCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
      );
    } else if (oldMethod == PaymentMethod.credit && newPaymentMethod != PaymentMethod.credit) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id, 
        customerName: sale.customerName ?? 'Unknown'
      );
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];
    
    final updateMap = <String, dynamic>{
      'paymentMethod': newPaymentMethod.name,
      'customerName': newPaymentMethod == PaymentMethod.credit ? newCustomerName : null,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    };
    
    if (newPaymentMethod == PaymentMethod.cash || newPaymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = sale.totalAmount;
      updateMap['remainingAmount'] = 0.0;
    } else if (newPaymentMethod == PaymentMethod.credit) {
      updateMap['paymentStatus'] = 'Outstanding';
      updateMap['paidAmount'] = 0.0;
      updateMap['remainingAmount'] = sale.totalAmount;
    }

    batch.update(_salesRef.doc(sale.id), updateMap);
    await batch.commit();
  }'''

sales_new_code = sales_pattern.sub(sales_replacement, sales_code)

if sales_new_code == sales_code:
    print("WARNING: QuickSalesRepository not modified.")
else:
    with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'w') as f:
        f.write(sales_new_code)
    print("QuickSalesRepository patched.")
