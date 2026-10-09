import re

with open('lib/features/games/data/games_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# I will replace the inside of updateOrders with robust diffing
old_updateOrders_pattern = re.compile(r"  Future<void> updateOrders\([\s\S]*?await batch\.commit\(\);\n  \}")

new_updateOrders = """  Future<void> updateOrders(
    String gameId,
    List<GameOrder> oldOrders,
    List<GameOrder> orders, [
    List<ManualGameCharge>? oldManualGames,
    List<ManualGameCharge>? manualGames,
  ]) async {
    if (AppConfig.guardWrite('GamesRepository.updateOrders')) return;

    final List<AuditLog> newLogs = [];
    final staffName = currentUserName ?? 'Unknown';
    final now = DateTime.now();
    int logIndex = 0; // To ensure unique IDs if generated in same millisecond

    // Orders diff using map
    final oldMap = <String, int>{};
    for (final o in oldOrders) {
      final key = '${o.productId}_${o.playerName ?? ""}';
      oldMap[key] = (oldMap[key] ?? 0) + o.quantity;
    }
    
    final newMap = <String, int>{};
    final nameMap = <String, String>{};
    for (final o in orders) {
      final key = '${o.productId}_${o.playerName ?? ""}';
      newMap[key] = (newMap[key] ?? 0) + o.quantity;
      nameMap[key] = o.productName;
    }

    for (final key in newMap.keys) {
      final oldQty = oldMap[key] ?? 0;
      final newQty = newMap[key]!;
      if (newQty > oldQty) {
        final diff = newQty - oldQty;
        newLogs.add(
          AuditLog(
            id: '${now.millisecondsSinceEpoch}_add_${logIndex++}',
            editedBy: staffName,
            timestamp: now,
            field: 'Order Added',
            previousValue: '-',
            newValue: '$diff x ${nameMap[key]}',
          ),
        );
      } else if (newQty < oldQty) {
        final diff = oldQty - newQty;
        newLogs.add(
          AuditLog(
            id: '${now.millisecondsSinceEpoch}_rem_${logIndex++}',
            editedBy: staffName,
            timestamp: now,
            field: 'Order Removed',
            previousValue: '-',
            newValue: '$diff x ${nameMap[key]}',
          ),
        );
      }
    }
    
    for (final key in oldMap.keys) {
      if (!newMap.containsKey(key)) {
        final productName = oldOrders
            .firstWhere((o) => '${o.productId}_${o.playerName ?? ""}' == key)
            .productName;
        newLogs.add(
          AuditLog(
            id: '${now.millisecondsSinceEpoch}_rem_${logIndex++}',
            editedBy: staffName,
            timestamp: now,
            field: 'Order Removed',
            previousValue: '-',
            newValue: '${oldMap[key]} x $productName',
          ),
        );
      }
    }

    // Manual Games diff
    if (manualGames != null && oldManualGames != null) {
      final oldManualMap = {for (var m in oldManualGames) m.id: m};
      final newManualMap = {for (var m in manualGames) m.id: m};

      for (final m in manualGames) {
        if (!oldManualMap.containsKey(m.id)) {
          newLogs.add(
            AuditLog(
              id: '${now.millisecondsSinceEpoch}_madd_${logIndex++}',
              editedBy: staffName,
              timestamp: now,
              field: 'Manual Charge Added',
              previousValue: '-',
              newValue: '?${m.calculatedAmount.toStringAsFixed(2)} - ${m.tableName} - ${m.gameType.name}',
            ),
          );
        }
      }
      for (final m in oldManualGames) {
        if (!newManualMap.containsKey(m.id)) {
          newLogs.add(
            AuditLog(
              id: '${now.millisecondsSinceEpoch}_mrem_${logIndex++}',
              editedBy: staffName,
              timestamp: now,
              field: 'Manual Charge Removed',
              previousValue: '-',
              newValue: '?${m.calculatedAmount.toStringAsFixed(2)} - ${m.tableName} - ${m.gameType.name}',
            ),
          );
        }
      }
    }

    final batch = _db.batch();
    final updateMap = <String, dynamic>{
      'orders': orders.map((o) => o.toMap()).toList(),
    };
    if (manualGames != null) {
      updateMap['manualGameCharges'] = manualGames
          .map((m) => m.toMap())
          .toList();
    }
    if (newLogs.isNotEmpty) {
      updateMap['auditLogs'] = FieldValue.arrayUnion(
        newLogs.map((l) => l.toMap()).toList(),
      );
    }
    batch.update(_gamesRef.doc(gameId), updateMap);
    await batch.commit();
  }"""

if not old_updateOrders_pattern.search(content):
    print("Could not find updateOrders method!")
else:
    content = old_updateOrders_pattern.sub(new_updateOrders, content)
    with open('lib/features/games/data/games_repository.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched updateOrders successfully.")
