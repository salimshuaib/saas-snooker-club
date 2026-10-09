import re

with open('lib/features/games/data/games_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: updateOrders
old_updateOrders = """  Future<void> updateOrders(
    String gameId,
    List<GameOrder> oldOrders,
    List<GameOrder> orders, [
    List<ManualGameCharge>? oldManualGames,
    List<ManualGameCharge>? manualGames,
  ]) async {
    if (AppConfig.guardWrite('GamesRepository.updateOrders')) return;

    final List<AuditLog> newLogs = [];
    // Note: audit log logic simplified for brevity
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

    // Orders diff
    final diff = orders.length - oldOrders.length;
    if (diff > 0) {
      final added = orders.last;
      newLogs.add(AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_order_add',
        editedBy: staffName,
        timestamp: DateTime.now(),
        field: 'Order Added',
        previousValue: '-',
        newValue: '${added.quantity} x ${added.productName}',
      ));
    } else if (diff < 0) {
      newLogs.add(AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_order_remove',
        editedBy: staffName,
        timestamp: DateTime.now(),
        field: 'Order Removed',
        previousValue: '${oldOrders.length} orders',
        newValue: '${orders.length} orders',
      ));
    }

    // Manual Games diff
    if (manualGames != null && oldManualGames != null) {
      final manualDiff = manualGames.length - oldManualGames.length;
      if (manualDiff > 0) {
        final added = manualGames.last;
        newLogs.add(AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_manual_add',
          editedBy: staffName,
          timestamp: DateTime.now(),
          field: 'Manual Charge Added',
          previousValue: '-',
          newValue: '?${added.calculatedAmount.toStringAsFixed(2)} - ${added.description}',
        ));
      } else if (manualDiff < 0) {
        newLogs.add(AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_manual_rem',
          editedBy: staffName,
          timestamp: DateTime.now(),
          field: 'Manual Charge Removed',
          previousValue: '${oldManualGames.length} charges',
          newValue: '${manualGames.length} charges',
        ));
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

content = content.replace(old_updateOrders, new_updateOrders)

with open('lib/features/games/data/games_repository.dart', 'w', encoding='utf-8') as f:
    f.write(content)
