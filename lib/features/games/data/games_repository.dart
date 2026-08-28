import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/games/domain/config/tables_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/credit/data/credit_repository.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

/// Repository for all Games-related Firebase operations.
/// Handles Tables and Game Sessions.
class GamesRepository {
  final FirebaseFirestore _db;
  final Ref? _ref;
  final String? clubId;
  
  GamesRepository({FirebaseFirestore? db, Ref? ref, this.clubId}) : _db = db ?? FirebaseFirestore.instance, _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

  DocumentReference get _clubRef {
    if (clubId == null) throw Exception('clubId cannot be null for GamesRepository');
    return _db.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _tablesRef => _clubRef.collection(FirebaseConstants.tablesCollection);

  CollectionReference get _gamesRef => _clubRef.collection(FirebaseConstants.gamesCollection);

  GameSession _enrichWithStaff(GameSession session, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return session;
    
    if (isCreate) {
      return session.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return session.copyWith(
        updatedByUserId: staff.id,
        updatedByName: staff.name,
      );
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // Tables
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  /// Real-time stream of all tables.
  Stream<List<TableModel>> watchTables() {
    return _tablesRef.snapshots().map((snapshot) {
      final tables = snapshot.docs
          .map((doc) => TableModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      tables.sort((a, b) => a.order.compareTo(b.order));
      return tables;
    });
  }

  /// Seed initial tables if collection is empty.
  /// Called at app startup. Idempotent â€” safe to call multiple times.
  Future<void> addTable(TableModel table) async {
    if (AppConfig.guardWrite('GamesRepository.addTable')) return;
    await _tablesRef.doc(table.id).set(table.toMap());
  }

  Future<void> deleteTable(String tableId) async {
    if (AppConfig.guardWrite('GamesRepository.deleteTable')) return;
    await _tablesRef.doc(tableId).delete();
  }

  Future<void> seedTablesIfEmpty() async {
    if (AppConfig.guardWrite('GamesRepository.seedTablesIfEmpty')) return;
    try {
      final snapshot = await _tablesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Club already has tables, don't interfere with their configuration.
      }

      final tables = TablesConfig.defaultTables;

      AppLogger.info(
        'Seeding default tables for new club: ${tables.length} tables...',
      );
      final batch = _db.batch();
      for (int i = 0; i < tables.length; i++) {
        batch.set(_tablesRef.doc(tables[i].id), {
          ...tables[i].toMap(),
          'order': i,
        });
      }
      await batch.commit();
      AppLogger.info('Default tables seeded successfully.');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.warning(
          'Firestore permission denied â€” tables not seeded. '
          'Update Firestore rules to: allow read, write: if request.auth != null;',
        );
      } else {
        AppLogger.error('Failed to seed tables: $e');
      }
    } catch (e) {
      AppLogger.error('Failed to seed tables: $e');
    }
  }

  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? activeGameId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateTableStatus')) return;
    await _tablesRef.doc(tableId).update({
      'status': status.name,
      'activeGameId': activeGameId,
    });
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  // Game Sessions
  // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  /// Real-time stream of games for a given table and date.
  Future<List<GameSession>> getGamesForPlayer(
    String playerId,
    String playerName,
  ) async {
    final futures = [
      _gamesRef.where('playerIds', arrayContains: playerId).get(),
      _gamesRef.where('teamA', arrayContains: playerName).get(),
      _gamesRef.where('teamB', arrayContains: playerName).get(),
    ];
    final results = await Future.wait(futures);
    final uniqueGames = <String, GameSession>{};
    for (final snap in results) {
      for (final doc in snap.docs) {
        if (!uniqueGames.containsKey(doc.id)) {
          uniqueGames[doc.id] = GameSession.fromMap(
            doc.data() as Map<String, dynamic>,
          );
        }
      }
    }
    final list = uniqueGames.values.toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Real-time stream of all completed games for analytics calculations.

  Stream<List<GameSession>> watchAllGamesByDate(String dateStr) {
    final start = DateTime.parse(dateStr);
    final end = start.add(const Duration(days: 1));
    return watchGamesByDateRange(start, end);
  }

  Stream<List<GameSession>> watchGamesByTableAndDate(
    String tableId,
    String dateStr,
  ) {
    final start = DateTime.parse(dateStr);
    final end = start.add(const Duration(days: 1));
    return _gamesRef.where('tableId', isEqualTo: tableId).snapshots().map((
      snapshot,
    ) {
      final docs = snapshot.docs
          .map((doc) => GameSession.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      final filtered = docs
          .where(
            (doc) =>
                (doc.startTime.isAfter(start) ||
                    doc.startTime.isAtSameMomentAs(start)) &&
                doc.startTime.isBefore(end),
          )
          .toList();
      filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
      return filtered;
    });
  }

  Stream<List<GameSession>> watchAllGames() {
    return _gamesRef.snapshots().map(
      (snap) => snap.docs
          .map((doc) => GameSession.fromMap(doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Real-time stream of game sessions within a specific date range to reduce Firebase reads.
  Stream<List<GameSession>> watchGamesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _gamesRef
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    GameSession.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Paginated fetch for game history lists to avoid loading thousands of documents at once.
  Future<List<GameSession>> getGamesPaginated({
    DocumentSnapshot? lastDoc,
    int limit = 50,
  }) async {
    Query query = _gamesRef.orderBy('startTime', descending: true).limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => GameSession.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Real-time stream of the active game on a table.
  Stream<GameSession?> watchActiveGame(String tableId) {
    return _gamesRef.where('tableId', isEqualTo: tableId).snapshots().map((
      snap,
    ) {
      if (snap.docs.isEmpty) return null;
      final docs = snap.docs
          .map((doc) => GameSession.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      final active = docs
          .where(
            (g) =>
                g.status == TableStatus.running ||
                g.status == TableStatus.paused,
          )
          .toList();
      if (active.isEmpty) return null;
      active.sort((a, b) => b.startTime.compareTo(a.startTime));
      return active.first;
    });
  }

  /// Create a new game session and mark the table as running.
  Future<GameSession> startGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.startGame')) return session;
    final enrichedSession = _enrichWithStaff(session, true);
    final docRef = _gamesRef.doc(enrichedSession.id);
    final batch = _db.batch();
    batch.set(docRef, enrichedSession.toMap());
    batch.update(_tablesRef.doc(session.tableId), {
      'status': TableStatus.running.name,
      'activeGameId': session.id,
    });
    await batch.commit();
    AppLogger.info('Game started: ${session.id} on ${session.tableId}');
    return session;
  }

  /// Fetch a single game by its ID.
  Future<GameSession?> getGameById(String gameId) async {
    final doc = await _gamesRef.doc(gameId).get();
    if (!doc.exists) return null;
    return GameSession.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Pause the current game.
  Future<void> pauseGame(
    String gameId,
    String tableId,
    DateTime pausedAt,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.pauseGame')) return;
    final batch = _db.batch();
    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.paused.name,
      'pauseTimes': FieldValue.arrayUnion([Timestamp.fromDate(pausedAt)]),
    });
    batch.update(_tablesRef.doc(tableId), {'status': TableStatus.paused.name});
    await batch.commit();
  }

  /// Resume a paused game.
  Future<void> resumeGame(
    String gameId,
    String tableId,
    DateTime resumedAt,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.resumeGame')) return;
    final batch = _db.batch();
    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.running.name,
      'resumeTimes': FieldValue.arrayUnion([Timestamp.fromDate(resumedAt)]),
    });
    batch.update(_tablesRef.doc(tableId), {'status': TableStatus.running.name});
    await batch.commit();
  }

  /// Update orders on a running game.
  Future<void> updatePlayerPoints(String gameId, Map<String, int> playerPoints) async {
    if (AppConfig.guardWrite('GamesRepository.updatePlayerPoints')) return;
    await _gamesRef.doc(gameId).update({
      'playerPoints': playerPoints,
    });
  }

  Future<void> updateOrders(String gameId, List<GameOrder> orders) async {
    if (AppConfig.guardWrite('GamesRepository.updateOrders')) return;
    await _gamesRef.doc(gameId).update({
      'orders': orders.map((o) => o.toMap()).toList(),
    });
  }

  /// Update rounds and frame counters on a running game.
  Future<void> updateGameRounds(
    String gameId,
    List<GameRound> rounds,
    int totalFrames,
    int framesPlayed,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.updateGameRounds')) return;
    await _gamesRef.doc(gameId).update({
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'totalFrames': totalFrames,
      'framesPlayed': framesPlayed,
    });
  }

  /// Cancel an active game. Restores inventory and frees the table.
  Future<void> cancelGame(String gameId, String tableId, List<GameOrder> orders) async {
    if (AppConfig.guardWrite('GamesRepository.cancelGame')) return;
    
    final batch = _db.batch();
    
    // 1. Restore inventory
    if (orders.isNotEmpty) {
      final inventoryRef = _clubRef.collection(FirebaseConstants.inventoryCollection);
      final Map<String, int> stockRestorations = {};
      
      for (final order in orders) {
        stockRestorations[order.productId] = (stockRestorations[order.productId] ?? 0) + order.quantity;
      }
      
      for (final entry in stockRestorations.entries) {
        batch.update(inventoryRef.doc(entry.key), {
          'currentStock': FieldValue.increment(entry.value),
        });
      }
    }
    
    // 2. Delete game record
    batch.delete(_gamesRef.doc(gameId));
    
    // 3. Free the table
    batch.update(_tablesRef.doc(tableId), {'status': TableStatus.available.name});
    
    // 4. Audit log
    final auditRef = _clubRef.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'Game Cancelled',
      'recordId': gameId,
      'collection': FirebaseConstants.gamesCollection,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'Active game cancelled. ${orders.length} orders restocked.',
      'staffId': currentStaff?.id,
      'staffName': currentStaff?.name,
    });
    
    await batch.commit();
  }

  /// Mark the game as billing (about to finalize).
  Future<void> markBilling(String gameId, String tableId) async {
    if (AppConfig.guardWrite('GamesRepository.markBilling')) return;
    final batch = _db.batch();
    batch.update(_gamesRef.doc(gameId), {'status': TableStatus.billing.name});
    batch.update(_tablesRef.doc(tableId), {'status': TableStatus.billing.name});
    await batch.commit();
  }

  /// Finalize the game: record payment and free the table.
  Future<void> endGame(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.endGame')) return;
    final batch = _db.batch();

    final updateMap = <String, dynamic>{
      'status': TableStatus.available.name,
      'endTime': Timestamp.fromDate(session.endTime!),
      'orders': session.orders.map((o) => o.toMap()).toList(),
      'rounds': session.rounds.map((r) => r.toMap()).toList(),
      'playerPaymentMethods': session.playerPaymentMethods?.map(
        (k, v) => MapEntry(k, v.name),
      ),
      'playerLiabilities': session.playerLiabilities,
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
    };

    if (session.paymentMethod == PaymentMethod.credit) {
      updateMap['paidBy'] = session.paidBy;
    }

    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;

    if (session.paymentMethod == PaymentMethod.cash ||
        session.paymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = amountToPay;
      updateMap['remainingAmount'] = 0.0;
    }

    if (session.isManualEntry) {
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

    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    
    if (session.paymentMethod == null && session.playerPaymentMethods != null && session.playerPaymentMethods!.isNotEmpty) {
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
            subtitle: 'Split Match (Ã¢â€šÂ¹${amount.toStringAsFixed(2)})',
            paymentMethod: paymentMethod,
          );
        }
      }
    } else if (session.paymentMethod != null && session.paidBy != null) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        customerId: session.playerIdentities != null ? session.playerIdentities![session.paidBy!] : null,
        amount: amountToPay,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: Ã¢â€šÂ¹${amountToPay.toStringAsFixed(2)}',
        paymentMethod: session.paymentMethod!,
      );
    }

    if (session.orders.isNotEmpty) {
      final inventoryRef = _clubRef.collection(
        FirebaseConstants.inventoryCollection,
      );
      final Map<String, int> stockDeductions = {};
      for (final order in session.orders) {
        stockDeductions[order.productId] =
            (stockDeductions[order.productId] ?? 0) + order.quantity;
      }
      for (final entry in stockDeductions.entries) {
        final docRef = inventoryRef.doc(entry.key);
        batch.update(docRef, {
          'currentStock': FieldValue.increment(-entry.value),
          'totalSold': FieldValue.increment(entry.value),
        });
      }
    }

    await batch.commit();
    AppLogger.info('Game ended: ${session.id}');
  }

  /// Get completed games for a date across all tables (for dashboard stats).
  Future<List<GameSession>> getGamesByDate(String date) async {
    final snap = await _gamesRef
        .where('date', isEqualTo: date)
        .where('status', isEqualTo: TableStatus.available.name)
        .get();
    return snap.docs
        .map((doc) => GameSession.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Delete game sessions and restore inventory stock if applicable.
  /// Only completed games may be deleted; active/running games throw an error.
  /// Automatically cascade-deletes associated credit transactions or blocks deletion if settled.
  Future<void> deleteGameSessions(List<GameSession> sessions) async {
    if (AppConfig.guardWrite('GamesRepository.deleteGameSessions')) return;
    if (sessions.isEmpty) return;
    for (final session in sessions) {
      if (session.status != TableStatus.available) {
        throw Exception('Cannot delete active or running games.');
      }
    }

    // 1. Cascade delete or validate credit records before any deletions occur
    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    await creditRepo.cascadeDeleteGameCredits(sessions);

    final batch = _db.batch();
    final inventoryRef = _clubRef.collection(FirebaseConstants.inventoryCollection);
    final Map<String, int> stockRestorations = {};

    for (final session in sessions) {
      // Delete game record
      batch.delete(_gamesRef.doc(session.id));

        // Audit Log for Deletion
        final auditRef = _clubRef.collection('audit_logs').doc();
        batch.set(auditRef, {
          'id': auditRef.id,
          'action': 'Game Deleted',
          'recordId': session.id,
          'module': 'Games',
          'userId': currentStaff?.id ?? 'Unknown',
          'userName': currentStaff?.name ?? 'Admin',
          'timestamp': FieldValue.serverTimestamp(),
        });

      // Aggregate inventory restoration if items were ordered
      for (final order in session.orders) {
        stockRestorations[order.productId] =
            (stockRestorations[order.productId] ?? 0) + order.quantity;
      }
    }

    // Apply inventory restorations
    for (final entry in stockRestorations.entries) {
      final docRef = inventoryRef.doc(entry.key);
      batch.update(docRef, {
        'currentStock': FieldValue.increment(entry.value),
        'totalSold': FieldValue.increment(-entry.value),
      });
    }

    await batch.commit();
    AppLogger.info(
      'Deleted ${sessions.length} game record(s) and restored stock if applicable.',
    );
  }

  /// Update player/customer names on a completed game session post-completion, logging an audit record
  /// and syncing with Credit module if credit was charged.
  Future<void> updateGameNames({
    required GameSession session,
    required List<String> newTeamA,
    required List<String> newTeamB,
    required String? newPaidBy,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGameNames')) return;
    final oldTeamA = session.teamA;
    final oldTeamB = session.teamB;
    final oldPaidBy = session.paidBy;

    bool changed = false;
    final List<AuditLog> newLogs = [];

    if (oldTeamA.join(', ') != newTeamA.join(', ') ||
        oldTeamB.join(', ') != newTeamB.join(', ')) {
      changed = true;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_names_${session.id}',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Player Names',
          previousValue:
              'Team A: ${oldTeamA.join(", ")}, Team B: ${oldTeamB.join(", ")}',
          newValue:
              'Team A: ${newTeamA.join(", ")}, Team B: ${newTeamB.join(", ")}',
        ),
      );
    }

    if (oldPaidBy != newPaidBy) {
      changed = true;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_payer_${session.id}',
          editedBy: employeeName,
          timestamp: DateTime.now(),
          field: 'Payer Name (Credit)',
          previousValue: oldPaidBy ?? 'None',
          newValue: newPaidBy ?? 'None',
        ),
      );
    }

    if (!changed) return;

    // Create mapping of old names to new names for payment methods and liabilities
    final Map<String, String> nameMap = {};
    for (int i = 0; i < oldTeamA.length; i++) {
      if (i < newTeamA.length && oldTeamA[i] != newTeamA[i]) {
        nameMap[oldTeamA[i]] = newTeamA[i];
      }
    }
    for (int i = 0; i < oldTeamB.length; i++) {
      if (i < newTeamB.length && oldTeamB[i] != newTeamB[i]) {
        nameMap[oldTeamB[i]] = newTeamB[i];
      }
    }

    Map<String, PaymentMethod>? newPaymentMethods;
    if (session.playerPaymentMethods != null) {
      newPaymentMethods = {};
      for (final entry in session.playerPaymentMethods!.entries) {
        final key = nameMap[entry.key] ?? entry.key;
        newPaymentMethods[key] = entry.value;
      }
    }

    Map<String, double>? newLiabilities;
    if (session.playerLiabilities != null) {
      newLiabilities = {};
      for (final entry in session.playerLiabilities!.entries) {
        final key = nameMap[entry.key] ?? entry.key;
        newLiabilities[key] = entry.value;
      }
    }

    String? newWinner = session.winnerId;
    if (newWinner != null && nameMap.containsKey(newWinner)) {
      newWinner = nameMap[newWinner];
    }

    // Sync with CreditRepository if credit was involved
    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;

    if (session.paymentMethod == PaymentMethod.credit &&
        oldPaidBy != null &&
        newPaidBy != null &&
        oldPaidBy != newPaidBy) {
      await creditRepo.transferCreditTransaction(
        referenceId: session.id,
        oldCustomerName: oldPaidBy,
        newCustomerName: newPaidBy,
        amount: amountToPay,
        type: CreditTransactionType.game,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: Ã¢â€šÂ¹${session.grandTotal?.toStringAsFixed(2)}',
      );
    }

    if (session.playerPaymentMethods != null) {
      for (final entry in session.playerPaymentMethods!.entries) {
        if (entry.value == PaymentMethod.credit &&
            nameMap.containsKey(entry.key)) {
          final oldName = entry.key;
          final newName = nameMap[oldName]!;
          final amount = session.playerLiabilities?[oldName] ?? 0.0;
          await creditRepo.transferCreditTransaction(
            referenceId: session.id,
            oldCustomerName: oldName,
            newCustomerName: newName,
            amount: amount,
            type: CreditTransactionType.game,
            title: 'Game on Table ${session.tableName}',
            subtitle:
                'T.P. Match Split Liability (Ã¢â€šÂ¹${amount.toStringAsFixed(2)})',
          );
        }
      }
    }

    final updatedAuditLogs = [...session.auditLogs, ...newLogs];

    await _gamesRef.doc(session.id).update({
      'teamA': newTeamA,
      'teamB': newTeamB,
      if (newPaidBy != null) 'paidBy': newPaidBy,
      if (newWinner != null) 'winnerId': newWinner,
      if (newPaymentMethods != null)
        'playerPaymentMethods': newPaymentMethods.map(
          (k, v) => MapEntry(k, v.name),
        ),
      if (newLiabilities != null) 'playerLiabilities': newLiabilities,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    });
    AppLogger.info('Updated names for game session ${session.id}');
  }

  /// Update whole game payment method or per-player split payment methods post-completion, logging an audit record
  /// and automatically syncing credit balances.
  Future<void> updateGamePaymentMethods({
    required GameSession session,
    PaymentMethod? newPaymentMethod,
    String? newPaidBy,
    Map<String, PaymentMethod>? newPlayerPaymentMethods,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGamePaymentMethods'))
      return;
    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    final List<AuditLog> newLogs = [];
    final batch = _db.batch();
    bool anyChanged = false;
    final updateMap = <String, dynamic>{};
    final amountToPay = session.finalAmount ?? session.grandTotal ?? 0.0;

    if (newPlayerPaymentMethods != null && newPlayerPaymentMethods.isNotEmpty) {
      final oldPlayerMethods = session.playerPaymentMethods ?? {};
      for (final entry in newPlayerPaymentMethods.entries) {
        final player = entry.key;
        final newMethod = entry.value;
        final oldMethod =
            oldPlayerMethods[player] ??
            session.paymentMethod ??
            PaymentMethod.cash;
        if (oldMethod != newMethod) {
          anyChanged = true;
          newLogs.add(
            AuditLog(
              id: '${session.id}_pay_$player',
              editedBy: employeeName,
              timestamp: DateTime.now(),
              field: 'Payment Method ($player)',
              previousValue: oldMethod.displayName,
              newValue: newMethod.displayName,
            ),
          );

          final amount =
              session.playerLiabilities?[player] ??
              amountToPay / newPlayerPaymentMethods.length;

          // Unconditionally append since appendCreditToBatch now handles all payment methods
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: player,
            customerId: session.playerIdentities != null ? session.playerIdentities![player] : null,
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Liability (Ã¢â€šÂ¹${amount.toStringAsFixed(2)})',
            paymentMethod: newMethod,
          );
          if (oldMethod == PaymentMethod.credit && newMethod != PaymentMethod.credit) {
            await creditRepo.removeCreditFromBatch(
              batch: batch,
              referenceId: session.id,
              customerName: player,
            );
          }
        }
      }
      if (anyChanged) {
        updateMap['playerPaymentMethods'] = newPlayerPaymentMethods.map(
          (k, v) => MapEntry(k, v.name),
        );
        updateMap['paymentMethod'] = null;
        updateMap['paidBy'] = null;
      }
    } else if (newPaymentMethod != null) {
      final oldMethod = session.paymentMethod ?? PaymentMethod.cash;
      if (oldMethod != newPaymentMethod) {
        anyChanged = true;
        newLogs.add(
          AuditLog(
            id: '${session.id}_pay',
            editedBy: employeeName,
            timestamp: DateTime.now(),
            field: 'Payment Method',
            previousValue: oldMethod.displayName,
            newValue: newPaymentMethod.displayName,
          ),
        );

        await creditRepo.appendCreditToBatch(
          batch: batch,
          customerName: newPaidBy ?? 'Unknown',
          customerId: (newPaidBy != null && session.playerIdentities != null) ? session.playerIdentities![newPaidBy] : null,
          amount: amountToPay,
          type: CreditTransactionType.game,
          referenceId: session.id,
          title: 'Game on Table ${session.tableName}',
          paymentMethod: newPaymentMethod,
        );
        if (oldMethod == PaymentMethod.credit && newPaymentMethod != PaymentMethod.credit) {
          await creditRepo.removeCreditFromBatch(
            batch: batch,
            referenceId: session.id,
            customerName: session.paidBy ?? 'Unknown',
          );
        }
      }

      if (session.paidBy != newPaidBy &&
          newPaymentMethod == PaymentMethod.credit) {
        anyChanged = true;
        newLogs.add(
          AuditLog(
            id: '_payer',
            editedBy: employeeName,
            timestamp: DateTime.now(),
            field: 'Payer Name',
            previousValue: session.paidBy ?? 'None',
            newValue: newPaidBy ?? 'None',
          ),
        );
      }

      if (anyChanged) {
        final finalPaidBy = newPaymentMethod == PaymentMethod.credit
            ? newPaidBy
            : null;
        updateMap['paymentMethod'] = newPaymentMethod.name;
        updateMap['paidBy'] = finalPaidBy;

        if (newPaymentMethod == PaymentMethod.cash ||
            newPaymentMethod == PaymentMethod.upi) {
          updateMap['paymentStatus'] = 'Paid';
          updateMap['paidAmount'] = amountToPay;
          updateMap['remainingAmount'] = 0.0;
        } else if (newPaymentMethod == PaymentMethod.credit) {
          updateMap['paymentStatus'] = 'Outstanding';
          updateMap['paidAmount'] = 0.0;
          updateMap['remainingAmount'] = amountToPay;
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


  Stream<List<OtherGameResource>> watchOtherGames() {
    return const Stream.empty();
  }

  Stream<List<OtherGameResource>> watchAllOtherGamesManagement() {
    return const Stream.empty();
  }

  Future<void> addOtherGame(OtherGameResource resource) async {}
  Future<void> updateOtherGame(OtherGameResource resource) async {}

