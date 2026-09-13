import os

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# 2. Add teamA, teamB, playerIds, playerIdentities to updateMap
old_map = """    final updateMap = <String, dynamic>{
      'status': TableStatus.available.name,
      'endTime': Timestamp.fromDate(session.endTime!),
      'orders': session.orders.map((o) => o.toMap()).toList(),
      'rounds': session.rounds.map((r) => r.toMap()).toList(),
      'playerPaymentSplits': session.playerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
      ),
      'playerLiabilities': session.playerLiabilities,
      'selectedPayers': session.selectedPayers,
      'discountAmount': session.discountAmount,
      'discountedGameCharge': session.discountedGameCharge,
      'winnerId': session.winnerId,
      'paymentMethod': session.paymentMethod?.name,
      'gameCharge': session.gameCharge,
      'baseGameCharge': session.baseGameCharge,
      'overtimeMinutes': session.overtimeMinutes,
      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'grandTotal': session.grandTotal,
      'roundedAmount': session.roundedAmount,
      'finalAmount': session.finalAmount,
      'totalFrames': session.totalFrames,
      'framesPlayed': session.framesPlayed,
      'date': session.date,
    };"""

new_map = """    final updateMap = <String, dynamic>{
      'status': TableStatus.available.name,
      'endTime': Timestamp.fromDate(session.endTime!),
      'orders': session.orders.map((o) => o.toMap()).toList(),
      'rounds': session.rounds.map((r) => r.toMap()).toList(),
      'playerPaymentSplits': session.playerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
      ),
      'playerLiabilities': session.playerLiabilities,
      'selectedPayers': session.selectedPayers,
      'discountAmount': session.discountAmount,
      'discountedGameCharge': session.discountedGameCharge,
      'winnerId': session.winnerId,
      'paymentMethod': session.paymentMethod?.name,
      'gameCharge': session.gameCharge,
      'baseGameCharge': session.baseGameCharge,
      'overtimeMinutes': session.overtimeMinutes,
      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'grandTotal': session.grandTotal,
      'roundedAmount': session.roundedAmount,
      'finalAmount': session.finalAmount,
      'totalFrames': session.totalFrames,
      'framesPlayed': session.framesPlayed,
      'date': session.date,
      'teamA': session.teamA,
      'teamB': session.teamB,
      'playerIds': session.playerIds,
      'playerIdentities': session.playerIdentities,
    };"""

text = text.replace(old_map, new_map)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
