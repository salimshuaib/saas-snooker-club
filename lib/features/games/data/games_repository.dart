import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/games/domain/config/tables_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/credit/data/credit_repository.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';

/// Repository for all Games-related Firebase operations.
/// Handles Tables and Game Sessions.
class GamesRepository {
  final FirebaseFirestore _db;
  final Ref? _ref;
  final String? clubId;

  GamesRepository({FirebaseFirestore? db, Ref? ref, this.clubId})
    : _db = db ?? FirebaseFirestore.instance,
      _ref = ref;

  StaffMember? get currentStaff => _ref?.read(currentStaffProvider).value;

  String get currentUserName {
    try {
      final club = _ref?.read(clubProfileProvider).value;
      final staff = currentStaff;
      if (staff != null) {
        if (staff.role == StaffRole.owner &&
            club != null &&
            club.ownerName.isNotEmpty) {
          return club.ownerName;
        }
        if (staff.name.isNotEmpty &&
            staff.name != 'Admin' &&
            staff.name != 'Club Owner') {
          return staff.name;
        }
      }
      if (club != null && club.ownerName.isNotEmpty) return club.ownerName;
    } catch (_) {}
    return 'Admin';
  }

  String get currentUserId {
    final staff = currentStaff;
    if (staff != null) return staff.id;
    try {
      final club = _ref?.read(clubProfileProvider).value;
      if (club != null) return club.ownerUid;
    } catch (_) {}
    return 'Unknown';
  }

  DocumentReference get _clubRef {
    if (clubId == null)
      throw Exception('clubId cannot be null for GamesRepository');
    return _db.collection(FirebaseConstants.clubsCollection).doc(clubId);
  }

  CollectionReference get _tablesRef =>
      _clubRef.collection(FirebaseConstants.tablesCollection);

  CollectionReference get _gamesRef =>
      _clubRef.collection(FirebaseConstants.gamesCollection);

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

    if (table.id.isEmpty) {
      final docRef = _tablesRef.doc();
      final tableWithId = table.copyWith(id: docRef.id);
      await docRef.set(tableWithId.toMap());
    } else {
      await _tablesRef.doc(table.id).set(table.toMap());
    }
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

  Future<void> updateTable(TableModel table) async {
    if (AppConfig.guardWrite('GamesRepository.updateTable')) return;
    await _tablesRef.doc(table.id).update(table.toMap());
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

  /// Save a game record without marking the table as running (used for instant-bill games like Arcade).
  Future<GameSession> saveGameOnly(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.saveGameOnly')) return session;
    final enrichedSession = _enrichWithStaff(session, true);
    final docRef = _gamesRef.doc(enrichedSession.id);
    await docRef.set(enrichedSession.toMap());
    AppLogger.info('Game saved (no table update): ${session.id}');
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
  Future<void> updatePlayerPoints(
    String gameId,
    Map<String, int> playerPoints,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.updatePlayerPoints')) return;
    await _gamesRef.doc(gameId).update({'playerPoints': playerPoints});
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
  Future<void> cancelGame(
    String gameId,
    String tableId,
    List<GameOrder> orders,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.cancelGame')) return;

    final batch = _db.batch();

    // 1. Restore inventory
    if (orders.isNotEmpty) {
      final inventoryRef = _clubRef.collection(
        FirebaseConstants.inventoryCollection,
      );
      final Map<String, int> stockRestorations = {};

      for (final order in orders) {
        stockRestorations[order.productId] =
            (stockRestorations[order.productId] ?? 0) + order.quantity;
      }

      for (final entry in stockRestorations.entries) {
        batch.update(inventoryRef.doc(entry.key), {
          'currentStock': FieldValue.increment(entry.value),
        });
      }
    }

    // 2. Mark game as cancelled instead of deleting
    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.available.name,
      'isCancelled': true,
      'endTime': FieldValue.serverTimestamp(),
      'paymentStatus': 'Cancelled',
      'gameCharge': 0.0,
      'grandTotal': 0.0,
      'ordersTotal': 0.0,
      'finalAmount': 0.0,
    });

    // 3. Free the table
    batch.update(_tablesRef.doc(tableId), {
      'status': TableStatus.available.name,
    });

    // 4. Audit log
    final auditRef = _clubRef.collection('audit_logs').doc();
    batch.set(auditRef, {
      'id': auditRef.id,
      'action': 'Game Cancelled',
      'recordId': gameId,
      'collection': FirebaseConstants.gamesCollection,
      'timestamp': FieldValue.serverTimestamp(),
      'details': 'Active game cancelled. ${orders.length} orders restocked.',
      'staffId': currentUserId == 'Unknown' ? null : currentUserId,
      'staffName': currentUserName,
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
      'startTime': Timestamp.fromDate(session.startTime),
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
      'auditLogs': session.auditLogs.map((a) => a.toMap()).toList(),
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

    if (session.isManualEntry || session.tableType == TableType.arcade) {
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

    if (session.paymentMethod == null &&
        session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty) {
      for (final playerEntry in session.playerPaymentSplits!.entries) {
        final customerName = playerEntry.key;
        final splits = playerEntry.value;

        final creditAmount = splits[PaymentMethod.credit] ?? 0.0;

        if (creditAmount > 0) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: customerName,
            customerId: session.playerIdentities != null
                ? session.playerIdentities![customerName]
                : null,
            amount: creditAmount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Match (₹${creditAmount.toStringAsFixed(2)})',
            paymentMethod: PaymentMethod.credit,
          );
        }
      }
    } else if (session.paymentMethod == PaymentMethod.credit &&
        session.paidBy != null) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        customerId: session.playerIdentities != null
            ? session.playerIdentities![session.paidBy!]
            : null,
        amount: amountToPay,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: \u20B9${amountToPay.toStringAsFixed(2)}',
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
    final inventoryRef = _clubRef.collection(
      FirebaseConstants.inventoryCollection,
    );
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
        'userId': currentUserId,
        'userName': currentUserName,
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
    required List<String> newPlayers,
    required String? newPaidBy,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGameNames')) return;
    final oldPlayers = session.players;
    final oldPaidBy = session.paidBy;

    bool changed = false;
    final List<AuditLog> newLogs = [];

    if (oldPlayers.join(', ') != newPlayers.join(', ')) {
      changed = true;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_names_${session.id}',
          editedBy: currentUserName,
          timestamp: DateTime.now(),
          field: 'Player Names',
          previousValue: 'Players: ${oldPlayers.join(", ")}',
          newValue: 'Players: ${newPlayers.join(", ")}',
        ),
      );
    }

    if (oldPaidBy != newPaidBy) {
      changed = true;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_payer_${session.id}',
          editedBy: currentUserName,
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
    for (int i = 0; i < oldPlayers.length; i++) {
      if (i < newPlayers.length && oldPlayers[i] != newPlayers[i]) {
        nameMap[oldPlayers[i]] = newPlayers[i];
      }
    }

    Map<String, Map<PaymentMethod, double>>? newPaymentSplits;
    if (session.playerPaymentSplits != null) {
      newPaymentSplits = {};
      for (final entry in session.playerPaymentSplits!.entries) {
        final key = nameMap[entry.key] ?? entry.key;
        newPaymentSplits[key] = entry.value;
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

    List<String>? newSelectedPayers;
    if (session.selectedPayers != null) {
      newSelectedPayers = session.selectedPayers!
          .map((p) => nameMap[p] ?? p)
          .toList();
    }

    List<GameRound>? newRounds;
    if (session.rounds.isNotEmpty) {
      newRounds = session.rounds.map((round) {
        if (round.framePayers == null) return round;
        return round.copyWith(
          framePayers: round.framePayers!.map((p) => nameMap[p] ?? p).toList(),
        );
      }).toList();
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
        subtitle: 'Billed Amount: ₹${amountToPay.toStringAsFixed(2)}',
      );
    }

    if (session.playerPaymentSplits != null) {
      for (final entry in session.playerPaymentSplits!.entries) {
        final splits = entry.value;
        if ((splits[PaymentMethod.credit] ?? 0.0) > 0.0 &&
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
                'T.P. Match Split Liability (\u20B9${amount.toStringAsFixed(2)})',
          );
        }
      }
    }

    final updatedAuditLogs = [...session.auditLogs, ...newLogs];

    await _gamesRef.doc(session.id).update({
      'players': newPlayers,
      if (newPaidBy != null) 'paidBy': newPaidBy,
      if (newWinner != null) 'winnerId': newWinner,
      if (newPaymentSplits != null)
        'playerPaymentSplits': newPaymentSplits.map(
          (k, v) => MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
        ),
      if (newLiabilities != null) 'playerLiabilities': newLiabilities,
      if (newSelectedPayers != null) 'selectedPayers': newSelectedPayers,
      if (newRounds != null) 'rounds': newRounds.map((r) => r.toMap()).toList(),
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    });
    AppLogger.info('Updated names for game session ${session.id}');
  }

  /// Update whole game payment method or per-player split payment methods post-completion, logging an audit record
  /// and automatically syncing credit balances.
  /// Update per-player split payment methods post-completion.
  Future<void> updateGameSplitPaymentMethods({
    required GameSession session,
    required Map<String, PaymentMethod> updatedMethods,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateGameSplitPaymentMethods'))
      return;
    if (session.playerPaymentSplits == null) return;

    final creditRepo = CreditRepository(_db, ref: _ref, clubId: clubId);
    final List<AuditLog> newLogs = [];
    final batch = _db.batch();
    bool anyChanged = false;
    final updateMap = <String, dynamic>{};

    // Create new playerPaymentSplits map
    final Map<String, Map<PaymentMethod, double>> newSplits = {};
    double totalPaid = 0.0;
    double totalCredit = 0.0;

    for (final entry in session.playerPaymentSplits!.entries) {
      final playerName = entry.key;
      final oldSplits = entry.value;
      if (oldSplits.isEmpty) continue;

      final oldMethod = oldSplits.keys.first;
      final amount = oldSplits.values.first;
      final newMethod = updatedMethods[playerName] ?? oldMethod;

      newSplits[playerName] = {newMethod: amount};

      if (newMethod == PaymentMethod.cash || newMethod == PaymentMethod.upi) {
        totalPaid += amount;
      } else if (newMethod == PaymentMethod.credit) {
        totalCredit += amount;
      }

      if (oldMethod != newMethod) {
        anyChanged = true;
        newLogs.add(
          AuditLog(
            id: '${session.id}_${playerName}_pay',
            editedBy: currentUserName,
            timestamp: DateTime.now(),
            field: 'Payment ($playerName)',
            previousValue: oldMethod.displayName,
            newValue: newMethod.displayName,
          ),
        );

        if (oldMethod == PaymentMethod.credit) {
          // Remove old credit
          await creditRepo.removeCreditFromBatch(
            batch: batch,
            referenceId: session.id,
            customerName: playerName,
          );
        }

        if (newMethod == PaymentMethod.credit) {
          // Add new credit
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: playerName,
            customerId: session.playerIdentities?[playerName],
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            paymentMethod: newMethod,
          );
        }
      }
    }

    if (anyChanged) {
      final updatedAuditLogs = [...session.auditLogs, ...newLogs];
      updateMap['auditLogs'] = updatedAuditLogs.map((a) => a.toMap()).toList();

      updateMap['playerPaymentSplits'] = newSplits.map(
        (k, v) => MapEntry(k, v.map((km, vm) => MapEntry(km.name, vm))),
      );

      updateMap['paidAmount'] = totalPaid;
      updateMap['remainingAmount'] = totalCredit;

      if (totalCredit == 0) {
        updateMap['paymentStatus'] = 'Paid';
      } else if (totalPaid == 0) {
        updateMap['paymentStatus'] = 'Outstanding';
      } else {
        updateMap['paymentStatus'] = 'Partially Paid';
      }

      batch.update(_gamesRef.doc(session.id), updateMap);
      await batch.commit();
    }
  }

  Future<void> updateGamePaymentMethods({
    required GameSession session,
    PaymentMethod? newPaymentMethod,
    String? newPaidBy,
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
    if (newPaymentMethod != null) {
      final oldMethod = session.paymentMethod ?? PaymentMethod.cash;
      if (oldMethod != newPaymentMethod) {
        anyChanged = true;
        newLogs.add(
          AuditLog(
            id: '${session.id}_pay',
            editedBy: currentUserName,
            timestamp: DateTime.now(),
            field: 'Payment Method',
            previousValue: oldMethod.displayName,
            newValue: newPaymentMethod.displayName,
          ),
        );

        if (newPaymentMethod == PaymentMethod.credit) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: newPaidBy ?? 'Unknown',
            customerId: (newPaidBy != null && session.playerIdentities != null)
                ? session.playerIdentities![newPaidBy]
                : null,
            amount: amountToPay,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            paymentMethod: newPaymentMethod,
          );
        }
        if (oldMethod == PaymentMethod.credit &&
            newPaymentMethod != PaymentMethod.credit) {
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
            editedBy: currentUserName,
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

  /// Fully edits a completed bill: changes payer count, re-splits amounts,
  /// multi-method per player, syncs credit entries, and logs audit trail.
  Future<void> editCompletedBill({
    required GameSession session,
    required double newBillTotal,
    required Map<String, Map<PaymentMethod, double>> newPlayerPaymentSplits,
    required List<String> newSelectedPayers,
    required Map<String, double> newPlayerLiabilities,
    PaymentMethod? newPaymentMethod,
    String? newPaidBy,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.editCompletedBill')) return;
    final creditRepo = _ref?.read(creditRepositoryProvider);
    final batch = _db.batch();
    final List<AuditLog> newLogs = [];
    final String editor = currentStaff?.name ?? 'Admin';

    // ── 1. Determine old credit entries ──
    final Map<String, double> oldCreditAmounts = {};
    if (session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty) {
      for (final entry in session.playerPaymentSplits!.entries) {
        final creditAmt = entry.value[PaymentMethod.credit] ?? 0.0;
        if (creditAmt > 0) {
          oldCreditAmounts[entry.key] = creditAmt;
        }
      }
    } else if (session.paymentMethod == PaymentMethod.credit) {
      final payer = session.paidBy ?? session.players.firstOrNull ?? '';
      final amount = session.finalAmount ?? session.grandTotal ?? 0.0;
      if (payer.isNotEmpty && amount > 0) {
        oldCreditAmounts[payer] = amount;
      }
    }

    // ── 2. Determine new credit entries ──
    final Map<String, double> newCreditAmounts = {};
    for (final entry in newPlayerPaymentSplits.entries) {
      final creditAmt = entry.value[PaymentMethod.credit] ?? 0.0;
      if (creditAmt > 0) {
        newCreditAmounts[entry.key] = creditAmt;
      }
    }

    // ── 3. Sync credit: remove old, add new ──
    if (creditRepo != null) {
      // Remove all old credit entries for this game
      for (final entry in oldCreditAmounts.entries) {
        try {
          await creditRepo.removeCreditFromBatch(
            batch: batch,
            referenceId: session.id,
            customerName: entry.key,
          );
        } catch (e) {
          // If credit has been partially paid, throw to block the edit
          rethrow;
        }
      }

      // Add new credit entries
      for (final entry in newCreditAmounts.entries) {
        await creditRepo.appendCreditToBatch(
          batch: batch,
          customerName: entry.key,
          amount: entry.value,
          type: CreditTransactionType.game,
          referenceId: session.id,
          title: '${session.tableName} - Game',
          subtitle: session.date,
          isTransfer: true, // bypass duplicate check since we just removed old ones
        );
      }
    }

    // ── 4. Build update map for game session ──
    final Map<String, dynamic> updateMap = {};

    // Payment splits
    updateMap['playerPaymentSplits'] = newPlayerPaymentSplits.map(
      (k, v) => MapEntry(k, v.map((k2, v2) => MapEntry(k2.name, v2))),
    );
    updateMap['playerLiabilities'] = newPlayerLiabilities;
    updateMap['selectedPayers'] = newSelectedPayers;

    // Bill total
    if ((newBillTotal - (session.finalAmount ?? session.grandTotal ?? 0.0)).abs() > 0.01) {
      updateMap['finalAmount'] = newBillTotal;
      updateMap['roundedAmount'] = newBillTotal;
    }

    // Overall payment method (for single payer, single method case)
    if (newPaymentMethod != null) {
      updateMap['paymentMethod'] = newPaymentMethod.name;
    }
    if (newPaidBy != null) {
      updateMap['paidBy'] = newPaidBy;
    }

    // Update players list if payers changed
    final allPayerNames = newPlayerPaymentSplits.keys.toList();
    updateMap['teamA'] = allPayerNames;
    updateMap['players'] = allPayerNames;

    // Payment status
    if (newCreditAmounts.isNotEmpty) {
      // Has some credit
      final totalCredit = newCreditAmounts.values.fold<double>(0, (s, v) => s + v);
      if (totalCredit >= newBillTotal - 0.5) {
        updateMap['paymentStatus'] = 'Outstanding';
        updateMap['paidAmount'] = 0.0;
        updateMap['remainingAmount'] = newBillTotal;
      } else {
        updateMap['paymentStatus'] = 'Partially Paid';
        updateMap['paidAmount'] = newBillTotal - totalCredit;
        updateMap['remainingAmount'] = totalCredit;
      }
    } else {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = newBillTotal;
      updateMap['remainingAmount'] = 0.0;
    }

    // ── 5. Create audit log ──
    // Summarize old state
    String oldSummary = '';
    if (session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty) {
      oldSummary = session.playerPaymentSplits!.entries.map((e) {
        final methods = e.value.entries.map((m) => '₹${m.value.toStringAsFixed(0)} ${m.key.displayName}').join('+');
        return '${e.key}: $methods';
      }).join(', ');
    } else {
      oldSummary = '${session.paidBy ?? 'Unknown'}: ₹${(session.finalAmount ?? session.grandTotal ?? 0).toStringAsFixed(0)} ${session.paymentMethod?.displayName ?? 'Unknown'}';
    }

    // Summarize new state
    final newSummary = newPlayerPaymentSplits.entries.map((e) {
      final methods = e.value.entries.map((m) => '₹${m.value.toStringAsFixed(0)} ${m.key.displayName}').join('+');
      return '${e.key}: $methods';
    }).join(', ');

    newLogs.add(AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: editor,
      timestamp: DateTime.now(),
      field: 'Bill Edit (Full)',
      previousValue: oldSummary,
      newValue: newSummary,
    ));

    // If bill total changed
    final oldTotal = session.finalAmount ?? session.grandTotal ?? 0.0;
    if ((newBillTotal - oldTotal).abs() > 0.01) {
      newLogs.add(AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_total',
        editedBy: editor,
        timestamp: DateTime.now(),
        field: 'Bill Total',
        previousValue: '₹${oldTotal.toStringAsFixed(0)}',
        newValue: '₹${newBillTotal.toStringAsFixed(0)}',
      ));
    }

    final updatedAuditLogs = [...session.auditLogs, ...newLogs];
    updateMap['auditLogs'] = updatedAuditLogs.map((a) => a.toMap()).toList();

    // ── 6. Commit ──
    batch.update(_gamesRef.doc(session.id), updateMap);
    await batch.commit();

    // ── 7. Recalculate credit accounts ──
    if (creditRepo != null) {
      final allAffectedNames = <String>{
        ...oldCreditAmounts.keys,
        ...newCreditAmounts.keys,
      };
      for (final name in allAffectedNames) {
        final customer = await creditRepo.getCustomerByName(name);
        if (customer != null) {
          await creditRepo.recalculateCustomerAccount(customer.id);
        }
      }
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
