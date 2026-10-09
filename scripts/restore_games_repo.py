import sys

path = 'lib/features/games/data/games_repository.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add wipeCueZoneData
wipe_code = '''
  Future<void> wipeCueZoneData() async {
    print('Starting wipe of CueZone data for club: $clubId');
    final batch = _db.batch();

    // 1. Delete all games
    final gamesSnap = await _db.collection('clubs').doc(clubId).collection('games').get();
    for (var doc in gamesSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${gamesSnap.docs.length} games');

    // 2. Reset all tables
    final tablesSnap = await _db.collection('clubs').doc(clubId).collection('tables').get();
    for (var doc in tablesSnap.docs) {
      batch.update(doc.reference, {
        'status': 'available',
        'activeGameId': null,
        'isTimeNotSure': false,
      });
    }
    print('Resetting ${tablesSnap.docs.length} tables');

    // 3. Delete all player profiles (Khata customers)
    final playersSnap = await _db.collection('clubs').doc(clubId).collection('customers').get();
    for (var doc in playersSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${playersSnap.docs.length} players');

    // 4. Delete all credit transactions
    final creditSnap = await _db.collection('clubs').doc(clubId).collection('credit_history').get();
    for (var doc in creditSnap.docs) {
      batch.delete(doc.reference);
    }
    print('Deleting ${creditSnap.docs.length} credit history entries');

    await batch.commit();
    print('Wipe complete!');
  }'''

content = content.replace('      return list;\n    });\n  }\n\n}', '      return list;\n    });\n  }' + wipe_code + '\n}')

# Add updatePendingBillOrders
update_method = '''
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
    }

    await batch.commit();
  }
'''

content = content.replace("    await batch.commit();\n  }\n\n  /// Update rounds", "    await batch.commit();\n  }\n" + update_method + "\n  /// Update rounds")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Restored games_repository.dart patches correctly')
