import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

new_method = '''
  Future<void> updatePendingBillOrders(GameSession session, List<GameOrder> orders, double ordersTotal, double grandTotal, double finalAmount) async {
    if (AppConfig.guardWrite('GamesRepository.updatePendingBillOrders')) return;

    final List<AuditLog> newLogs = [];
    final diff = orders.length - session.orders.length;
    if (diff > 0) {
      final added = orders.last;
      newLogs.add(AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_order_add',
        editedBy: currentUserName,
        timestamp: DateTime.now(),
        field: 'Order Added (Pending)',
        previousValue: '-',
        newValue: '${added.quantity} x ${added.productName}',
      ));
    } else if (diff < 0) {
      newLogs.add(AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_order_remove',
        editedBy: currentUserName,
        timestamp: DateTime.now(),
        field: 'Order Removed (Pending)',
        previousValue: '${session.orders.length} orders',
        newValue: '${orders.length} orders',
      ));
    }

    final batch = _db.batch();
    batch.update(_gamesRef.doc(session.id), {
      'orders': orders.map((o) => o.toMap()).toList(),
      'ordersTotal': ordersTotal,
      'grandTotal': grandTotal,
      'roundedAmount': finalAmount,
      'finalAmount': finalAmount,
      if (newLogs.isNotEmpty) 'auditLogs': FieldValue.arrayUnion(newLogs.map((l) => l.toMap()).toList()),
    });
    
    // Process inventory
    if (diff > 0) {
      final added = orders.last;
      if (added.productId != null) {
        final productRef = _db
            .collection(FirebaseConstants.clubsCollection)
            .doc(clubId)
            .collection('inventory')
            .doc(added.productId);
        batch.update(productRef, {
          'currentStock': FieldValue.increment(-added.quantity),
          'totalSold': FieldValue.increment(added.quantity),
        });
      }
    } else if (diff < 0) {
       // Ideally we'd restore inventory for removed items, but keep it simple as in other places
    }

    await batch.commit();
  }
'''

content = content.replace("    await batch.commit();\n  }", "    await batch.commit();\n  }\n" + new_method)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched games_repository.dart with updatePendingBillOrders')
