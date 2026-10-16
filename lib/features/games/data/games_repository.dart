import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> updateGameAlarm(String gameId, DateTime? alarmTime) async {
    final Map<String, dynamic> updateData = {
      'alarmTime': alarmTime != null ? Timestamp.fromDate(alarmTime) : null,
      'alarmSetByUserId': alarmTime != null ? currentUserId : null,
    };
    await _gamesRef.doc(gameId).update(updateData);
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
    try {
      await _tablesRef.doc(table.id).update(table.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        AppLogger.warning('Table ${table.id} not found for update, likely deleted.');
      } else {
        rethrow;
      }
    }
  }

  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? activeGameId,
  }) async {
    if (AppConfig.guardWrite('GamesRepository.updateTableStatus')) return;
    try {
      await _tablesRef.doc(tableId).update({
        'status': status.name,
        'activeGameId': activeGameId,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        AppLogger.warning('Table $tableId not found for status update, likely deleted.');
      } else {
        rethrow;
      }
    }
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

  /// Real-time stream of only active/paused games to save Firebase reads
  Stream<List<GameSession>> watchRunningGames() {
    return _gamesRef
        .where(
          'status',
          whereIn: [TableStatus.running.name, TableStatus.paused.name],
        )
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
    final enrichedSession = _enrichWithStaff(session, true).copyWith(
      alarmSetByUserId: session.alarmTime != null ? currentUserId : null,
    );

    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_start',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Started',
      previousValue: '-',
      newValue: session.tableName,
    );
    final finalSession = enrichedSession.copyWith(
      auditLogs: [...enrichedSession.auditLogs, newAuditLog],
    );

    final docRef = _gamesRef.doc(finalSession.id);
    final batch = _db.batch();
    batch.set(docRef, finalSession.toMap());
    batch.update(_tablesRef.doc(session.tableId), {
      'status': TableStatus.running.name,
      'activeGameId': session.id,
    });
    await batch.commit();
    AppLogger.info('Game started: ${session.id} on ${session.tableId}');
    return finalSession;
  }

  /// Save a game record without marking the table as running (used for instant-bill games like Arcade).
  Future<GameSession> saveGameOnly(GameSession session) async {
    if (AppConfig.guardWrite('GamesRepository.saveGameOnly')) return session;
    final enrichedSession = _enrichWithStaff(session, true).copyWith(
      alarmSetByUserId: session.alarmTime != null ? currentUserId : null,
    );

    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_start',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Started',
      previousValue: '-',
      newValue: session.tableName,
    );
    final finalSession = enrichedSession.copyWith(
      auditLogs: [...enrichedSession.auditLogs, newAuditLog],
    );

    final docRef = _gamesRef.doc(finalSession.id);
    await docRef.set(finalSession.toMap());
    AppLogger.info('Game saved (no table update): ${session.id}');
    return finalSession;
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

    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_pause',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Paused',
      previousValue: 'Running',
      newValue: 'Paused',
    );

    final batch = _db.batch();
    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.paused.name,
      'pauseTimes': FieldValue.arrayUnion([Timestamp.fromDate(pausedAt)]),
      'auditLogs': FieldValue.arrayUnion([newAuditLog.toMap()]),
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

    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_resume',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Resumed',
      previousValue: 'Paused',
      newValue: 'Running',
    );

    final batch = _db.batch();
    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.running.name,
      'resumeTimes': FieldValue.arrayUnion([Timestamp.fromDate(resumedAt)]),
      'auditLogs': FieldValue.arrayUnion([newAuditLog.toMap()]),
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

  Future<void> updateWaitlistPlayers(
    String gameId,
    List<WaitlistPlayer> oldPlayers,
    List<WaitlistPlayer> players,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.updateWaitlistPlayers')) return;
    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_waitlist',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Waitlist Updated',
      previousValue: oldPlayers.map((player) => player.name).join(', '),
      newValue: players.map((player) => player.name).join(', '),
    );
    await _gamesRef.doc(gameId).update({
      'waitlistPlayers': players.map((player) => player.toMap()).toList(),
      'auditLogs': FieldValue.arrayUnion([newAuditLog.toMap()]),
    });
  }

  Future<void> updateOrders(
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
  }

  Future<void> toggleOvertimeBilling(
    String gameId,
    bool isOvertimeEnabled,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.toggleOvertimeBilling')) return;
    await _gamesRef.doc(gameId).update({
      'isOvertimeEnabled': isOvertimeEnabled,
      'updatedByUserId': currentUserId,
      'updatedByName': currentUserName,
    });
  }

  Future<void> updatePendingBillOrders(
    GameSession session,
    List<GameOrder> orders,
    List<ManualGameCharge> manualGameCharges,
    double ordersTotal,
    double manualGamesTotal,
    double grandTotal,
    double finalAmount,
  ) async {
    if (AppConfig.guardWrite('GamesRepository.updatePendingBillOrders')) return;

    final List<AuditLog> newLogs = [];
    final diff = orders.length - session.orders.length;
    if (diff > 0) {
      final added = orders.last;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_order_add',
          editedBy: currentUserName,
          timestamp: DateTime.now(),
          field: 'Order Added (Pending)',
          previousValue: '-',
          newValue: '${added.quantity} x ${added.productName}',
        ),
      );
    } else if (diff < 0) {
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_order_remove',
          editedBy: currentUserName,
          timestamp: DateTime.now(),
          field: 'Order Removed (Pending)',
          previousValue: '${session.orders.length} orders',
          newValue: '${orders.length} orders',
        ),
      );
    }

    final gameDiff =
        manualGameCharges.length - session.manualGameCharges.length;
    if (gameDiff > 0) {
      final added = manualGameCharges.last;
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_game_add',
          editedBy: currentUserName,
          timestamp: DateTime.now(),
          field: 'Game Added (Pending)',
          previousValue: '-',
          newValue: '${added.tableName}',
        ),
      );
    } else if (gameDiff < 0) {
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_game_remove',
          editedBy: currentUserName,
          timestamp: DateTime.now(),
          field: 'Game Removed (Pending)',
          previousValue: '${session.manualGameCharges.length} games',
          newValue: '${manualGameCharges.length} games',
        ),
      );
    }

    final batch = _db.batch();
    batch.update(_gamesRef.doc(session.id), {
      'orders': orders.map((o) => o.toMap()).toList(),
      'manualGameCharges': manualGameCharges.map((g) => g.toMap()).toList(),
      'ordersTotal': ordersTotal,
      'grandTotal': grandTotal,
      'roundedAmount': finalAmount,
      'finalAmount': finalAmount,
      if (newLogs.isNotEmpty)
        'auditLogs': FieldValue.arrayUnion(
          newLogs.map((l) => l.toMap()).toList(),
        ),
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
    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_cancel',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Cancelled',
      previousValue: 'Running',
      newValue: 'Cancelled',
    );

    batch.update(_gamesRef.doc(gameId), {
      'status': TableStatus.cancelled.name,
      'isCancelled': true,
      'endTime': FieldValue.serverTimestamp(),
      'paymentStatus': 'Cancelled',
      'endedByName': currentUserName,
      'gameCharge': 0.0,
      'grandTotal': 0.0,
      'ordersTotal': 0.0,
      'finalAmount': 0.0,
      'cancelledByUserId': currentUserId == 'Unknown' ? null : currentUserId,
      'cancelledByName': currentUserName,
      'alarmTime': null,
      'auditLogs': FieldValue.arrayUnion([newAuditLog.toMap()]),
    });

    // 3. Free the table
    batch.update(_tablesRef.doc(tableId), {
      'status': TableStatus.available.name,
      'activeGameId': FieldValue.delete(),
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

    final newAuditLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_end',
      editedBy: currentUserName,
      timestamp: DateTime.now(),
      field: 'Game Ended',
      previousValue: 'Running',
      newValue: 'Ended',
    );
    final auditLogsData = session.auditLogs.map((l) => l.toMap()).toList();
    auditLogsData.add(newAuditLog.toMap());

    final batch = _db.batch();

    final updateMap = <String, dynamic>{
      'status': TableStatus.available.name,
      'endedByUserId': currentUserId == 'Unknown' ? null : currentUserId,
      'endedByName': currentUserName,
      'alarmTime': null,
      'auditLogs': auditLogsData,
      'startTime': Timestamp.fromDate(session.startTime),
      'endTime': Timestamp.fromDate(session.endTime!),
      'orders': session.orders.map((o) => o.toMap()).toList(),
      'manualGameCharges': session.manualGameCharges
          .map((g) => g.toMap())
          .toList(),
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
      'manualSelectedFinalAmount': session.manualSelectedFinalAmount,
      'appliedOfferId': session.appliedOfferId,
      'appliedOfferName': session.appliedOfferName,
      'appliedOfferCode': session.appliedOfferCode,
      'appliedOfferPrice': session.appliedOfferPrice,
      'standardPrice': session.standardPrice,
      'paymentStatus': session.paymentStatus,
      'processedByUserId':
          session.processedByUserId ??
          (currentUserId == 'Unknown' ? null : currentUserId),
      'processedByName': session.processedByName ?? currentUserName,
      'totalFrames': session.totalFrames,
      'framesPlayed': session.framesPlayed,
      'date': session.date,
      'teamA': session.teamA,
      'teamB': session.teamB,
      'playerIds': session.playerIds,
      'playerIdentities': session.playerIdentities,
      'isPrepaid': session.isPrepaid,
      'prepaidAmount': session.prepaidAmount,
      'prepaidDurationMinutes': session.prepaidDurationMinutes,
      'prepaidFrames': session.prepaidFrames,
      'prepaidPaymentMethod': session.prepaidPaymentMethod?.name,
      'prepaidPlayerPaymentSplits': session.prepaidPlayerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
      ),
      'prepaidPaidBy': session.prepaidPaidBy,
      'prepaidConfirmedAt': session.prepaidConfirmedAt?.toIso8601String(),
      'isOvertimeEnabled': session.isOvertimeEnabled,
      'settlementAmountPaid': session.settlementAmountPaid,
      'settlementPaymentMethod': session.settlementPaymentMethod?.name,
      'settlementPaymentSplits': session.settlementPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
      ),
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
    } else if (session.paymentMethod == PaymentMethod.credit) {
      final creditAmount = (session.isPrepaid &&
              session.prepaidPaymentMethod != PaymentMethod.credit)
          ? math.max(0.0, amountToPay - session.prepaidAmount)
          : amountToPay;
      final paidAmount = (session.isPrepaid &&
              session.prepaidPaymentMethod != PaymentMethod.credit)
          ? session.prepaidAmount
          : 0.0;
      updateMap['paymentStatus'] =
          paidAmount > 0 && creditAmount > 0 ? 'Partially Paid' : 'Outstanding';
      updateMap['paidAmount'] = paidAmount;
      updateMap['remainingAmount'] = creditAmount;
    } else if (session.paymentMethod == null &&
        session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty) {
      double totalCredit = 0.0;
      double totalPaid = 0.0;
      for (final splits in session.playerPaymentSplits!.values) {
        totalCredit += splits[PaymentMethod.credit] ?? 0.0;
        totalPaid += splits[PaymentMethod.cash] ?? 0.0;
        totalPaid += splits[PaymentMethod.upi] ?? 0.0;
      }
      updateMap['paidAmount'] = totalPaid;
      updateMap['remainingAmount'] = totalCredit;

      if (totalCredit >= amountToPay - 0.5) {
        updateMap['paymentStatus'] = 'Outstanding';
      } else if (totalPaid == 0) {
        updateMap['paymentStatus'] = 'Outstanding';
      } else if (totalCredit == 0) {
        updateMap['paymentStatus'] = 'Paid';
      } else {
        updateMap['paymentStatus'] = 'Partially Paid';
      }
    }

    if (session.isManualEntry || session.tableType == TableType.arcade) {
      final fullMap = session.toMap();
      fullMap['status'] = TableStatus.available.name;
      fullMap['paymentStatus'] =
          updateMap['paymentStatus'] ?? session.paymentStatus;
      fullMap['paidAmount'] = updateMap['paidAmount'] ?? session.paidAmount;
      fullMap['remainingAmount'] =
          updateMap['remainingAmount'] ?? session.remainingAmount;
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
      final creditAmount = (session.isPrepaid &&
              session.prepaidPaymentMethod != PaymentMethod.credit)
          ? math.max(0.0, amountToPay - session.prepaidAmount)
          : amountToPay;
      if (creditAmount > 0) {
        await creditRepo.appendCreditToBatch(
          batch: batch,
          customerName: session.paidBy!,
          customerId: session.playerIdentities != null
              ? session.playerIdentities![session.paidBy!]
              : null,
          amount: creditAmount,
          type: CreditTransactionType.game,
          referenceId: session.id,
          title: 'Game on Table ${session.tableName}',
          subtitle: 'Billed Amount: \u20B9${creditAmount.toStringAsFixed(2)}',
          paymentMethod: session.paymentMethod!,
        );
      }
    }

    if (session.orders.isNotEmpty) {
      final inventoryRef = _clubRef.collection(
        FirebaseConstants.inventoryCollection,
      );
      final Map<String, int> stockDeductions = {};
      final Map<String, int> foodSoldCounts = {};
      for (final order in session.orders) {
        if (order.category.trim().toLowerCase() == 'food') {
          foodSoldCounts[order.productId] =
              (foodSoldCounts[order.productId] ?? 0) + order.quantity;
        } else {
          stockDeductions[order.productId] =
              (stockDeductions[order.productId] ?? 0) + order.quantity;
        }
      }
      for (final entry in stockDeductions.entries) {
        final docRef = inventoryRef.doc(entry.key);
        batch.update(docRef, {
          'currentStock': FieldValue.increment(-entry.value),
          'totalSold': FieldValue.increment(entry.value),
        });
      }
      for (final entry in foodSoldCounts.entries) {
        final docRef = inventoryRef.doc(entry.key);
        batch.update(docRef, {
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
      final durationMins = (session.activeSeconds / 60).floor();
      final details =
          '${session.tableName} | ${session.billingType.name} | Total: ₹${(session.finalAmount ?? session.grandTotal ?? 0).toStringAsFixed(0)} | Players: ${session.allPlayers.isEmpty ? "None" : session.allPlayers.join(", ")}';
      final log = AuditLog(
        id: auditRef.id,
        editedBy: currentUserName,
        timestamp: DateTime.now(),
        field: session.isCancelled
            ? 'Cancelled Game Deleted'
            : 'Completed Game Deleted',
        previousValue: '${durationMins}m played',
        newValue: details,
      );
      final logData = log.toMap();
      logData['timestamp'] = FieldValue.serverTimestamp();
      batch.set(auditRef, logData);

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
          isTransfer:
              true, // bypass duplicate check since we just removed old ones
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
    if ((newBillTotal - (session.finalAmount ?? session.grandTotal ?? 0.0))
            .abs() >
        0.01) {
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
      final totalCredit = newCreditAmounts.values.fold<double>(
        0,
        (s, v) => s + v,
      );
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
      oldSummary = session.playerPaymentSplits!.entries
          .map((e) {
            final methods = e.value.entries
                .map(
                  (m) => '₹${m.value.toStringAsFixed(0)} ${m.key.displayName}',
                )
                .join('+');
            return '${e.key}: $methods';
          })
          .join(', ');
    } else {
      oldSummary =
          '${session.paidBy ?? 'Unknown'}: ₹${(session.finalAmount ?? session.grandTotal ?? 0).toStringAsFixed(0)} ${session.paymentMethod?.displayName ?? 'Unknown'}';
    }

    // Summarize new state
    final newSummary = newPlayerPaymentSplits.entries
        .map((e) {
          final methods = e.value.entries
              .map((m) => '₹${m.value.toStringAsFixed(0)} ${m.key.displayName}')
              .join('+');
          return '${e.key}: $methods';
        })
        .join(', ');

    newLogs.add(
      AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        editedBy: editor,
        timestamp: DateTime.now(),
        field: 'Bill Edit (Full)',
        previousValue: oldSummary,
        newValue: newSummary,
      ),
    );

    // If bill total changed
    final oldTotal = session.finalAmount ?? session.grandTotal ?? 0.0;
    if ((newBillTotal - oldTotal).abs() > 0.01) {
      newLogs.add(
        AuditLog(
          id: '${DateTime.now().millisecondsSinceEpoch}_total',
          editedBy: editor,
          timestamp: DateTime.now(),
          field: 'Bill Total',
          previousValue: '₹${oldTotal.toStringAsFixed(0)}',
          newValue: '₹${newBillTotal.toStringAsFixed(0)}',
        ),
      );
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

  /// Gets a stream of all audit logs
  Stream<List<AuditLog>> get auditLogsStream {
    return _clubRef
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AuditLog.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> markAsPendingBill(
    GameSession session, {
    required String customerId,
    required String customerName,
  }) async {
    AppConfig.guardWrite('GamesRepository.markAsPendingBill');
    final staff = <String, dynamic>{};
    final now = DateTime.now();

    final updateMap = {
      ...staff,
      'status': TableStatus.pendingBill.name,
      'paymentStatus': 'Pending',
      'pendingBillCustomerId': customerId,
      'pendingBillCustomerName': customerName,
      'markedPendingAt': now.toIso8601String(),
      'markedPendingByUserId': currentUserId,
      'markedPendingByName': currentUserName,

      'endTime': session.endTime?.toIso8601String() ?? now.toIso8601String(),
      'gameCharge': session.gameCharge,
      'baseGameCharge': session.baseGameCharge,
      'overtimeMinutes': session.overtimeMinutes,
      'overtimeCharge': session.overtimeCharge,
      'ordersTotal': session.ordersTotal,
      'orders': session.orders.map((order) => order.toMap()).toList(),
      'manualGameCharges': session.manualGameCharges
          .map((charge) => charge.toMap())
          .toList(),

      'grandTotal': session.grandTotal,
      'roundedAmount': session.roundedAmount,
      'finalAmount': session.finalAmount,
      'manualSelectedFinalAmount': session.manualSelectedFinalAmount,
      'discountAmount': session.discountAmount,
      'currentGameDiscountAmount': session.currentGameDiscountAmount,
      'playerPaymentSplits': session.playerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
      ),
      'playerLiabilities': session.playerLiabilities,
      'isPrepaid': session.isPrepaid,
      'prepaidAmount': session.prepaidAmount,
      'prepaidDurationMinutes': session.prepaidDurationMinutes,
      'prepaidFrames': session.prepaidFrames,
      'prepaidPaymentMethod': session.prepaidPaymentMethod?.name,
      'prepaidPlayerPaymentSplits': session.prepaidPlayerPaymentSplits?.map(
        (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
      ),
      'prepaidPaidBy': session.prepaidPaidBy,
      'prepaidConfirmedAt': session.prepaidConfirmedAt?.toIso8601String(),
      'isOvertimeEnabled': session.isOvertimeEnabled,
      'paidAmount': session.isPrepaid ? session.prepaidAmount : 0.0,
      'remainingAmount': session.isPrepaid
          ? math.max(0.0, (session.finalAmount ?? session.roundedAmount ?? 0.0) - session.prepaidAmount)
          : (session.finalAmount ?? session.roundedAmount ?? 0.0),
    };

    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Marked Pending',
      previousValue: 'Running',
      newValue: customerName,
    );
    final logMap = auditLog.toMap();

    final batch = _db.batch();

    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);

    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });

    // Clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {
        'status': TableStatus.available.name,
        'activeGameId': FieldValue.delete(),
      });
    }

    // Deduct inventory stock for orders
    if (session.orders.isNotEmpty) {
      for (final order in session.orders) {
        if (order.productId != null) {
          final productRef = _db
              .collection(FirebaseConstants.clubsCollection)
              .doc(clubId)
              .collection('inventory')
              .doc(order.productId);

          batch.update(productRef, {
            'currentStock': FieldValue.increment(-order.quantity),
            'totalSold': FieldValue.increment(order.quantity),
          });
        }
      }
    }

    // Global audit log
    final globalLogRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();

    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Pending Bill',
    });

    await batch.commit();
  }

  Future<void> markAsPendingBillWithSplits(
    GameSession session,
    List<Map<String, String>> players,
  ) async {
    AppConfig.guardWrite('GamesRepository.markAsPendingBillWithSplits');
    final staffName = currentUserName;
    final staffId = currentUserId;
    final now = DateTime.now();
    final batch = _db.batch();

    final splitCount = players.length;
    if (splitCount == 0) return;

    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);

    // Delete the original session so it doesn't show up in history
    batch.delete(gameRef);

    // Also clear the activeGameId from the table so it becomes available immediately
    if (session.tableId != null) {
      final tableRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.tablesCollection)
          .doc(session.tableId);
      batch.update(tableRef, {
        'status': TableStatus.available.name,
        'activeGameId': FieldValue.delete(),
      });
    }

    // Now loop and create new split sessions
    for (int i = 0; i < splitCount; i++) {
      final pId = players[i]['id']!;
      final pName = players[i]['name']!;

      final splitId = '${session.id}_split_$i';

      final auditLog = AuditLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_split_$i',
        editedBy: staffName,
        timestamp: now,
        field: 'Marked Pending (Split)',
        previousValue: 'Running',
        newValue: '1 of $splitCount assigned to $pName',
      );

      final splitSession = session.copyWith(
        id: splitId,
        status: TableStatus.pendingBill,
        paymentStatus: 'Pending',
        pendingBillCustomerId: pId,
        pendingBillCustomerName: pName,
        markedPendingAt: now,
        markedPendingByUserId: staffId,
        markedPendingByName: staffName,
        endTime: session.endTime ?? now,

        // Divide all charges by the number of splits
        gameCharge: (session.gameCharge ?? 0) / splitCount,
        baseGameCharge: (session.baseGameCharge ?? 0) / splitCount,
        overtimeCharge: (session.overtimeCharge ?? 0) / splitCount,
        ordersTotal: (session.ordersTotal ?? 0) / splitCount,
        discountAmount: (session.discountAmount ?? 0) / splitCount,
        currentGameDiscountAmount:
            (session.currentGameDiscountAmount ?? 0) / splitCount,
        manualGameCharges: session.manualGameCharges
            .map(
              (charge) => charge.copyWith(
                calculatedAmount: charge.calculatedAmount / splitCount,
                discountAmount: charge.discountAmount / splitCount,
              ),
            )
            .toList(),
        grandTotal: (session.grandTotal ?? 0) / splitCount,
        roundedAmount: (session.roundedAmount ?? 0) / splitCount,
        finalAmount: (session.finalAmount ?? 0) / splitCount,
        isPrepaid: session.isPrepaid,
        prepaidAmount: session.isPrepaid ? (session.prepaidAmount / splitCount) : 0.0,
        paidAmount: session.isPrepaid ? (session.prepaidAmount / splitCount) : 0.0,
        remainingAmount: session.isPrepaid
            ? math.max(0.0, ((session.finalAmount ?? session.roundedAmount ?? 0) / splitCount) - (session.prepaidAmount / splitCount))
            : ((session.finalAmount ?? session.roundedAmount ?? 0) / splitCount),
        customPrice:
            (session.gameCharge ?? 0) /
            splitCount, // Set custom price so recalculations don't break it
        isMinimumBillEnabled: false,
        auditLogs: [...session.auditLogs, auditLog],
      );

      final newGameRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(splitId);

      batch.set(newGameRef, _enrichWithStaff(splitSession, true).toMap());
    }

    await batch.commit();
  }

  Future<void> toggleTimeNotSure(
    String tableId,
    String? gameId,
    bool isNotSure,
  ) async {
    AppConfig.guardWrite('GamesRepository.toggleTimeNotSure');
    final batch = _db.batch();

    final tableRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.tablesCollection)
        .doc(tableId);
    batch.update(tableRef, {'isTimeNotSure': isNotSure});

    if (gameId != null) {
      final gameRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(gameId);
      batch.update(gameRef, {'isTimeNotSure': isNotSure});
    }

    await batch.commit();
  }

  Future<void> settlePendingBillsCombined(
    List<GameSession> bills, {
    required PaymentMethod? paymentMethod,
    required String? paidBy,
    required String customerName,
    required double roundedTotal,
    required Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
    double additionalDiscountAmount = 0.0,
  }) async {
    AppConfig.guardWrite('GamesRepository.settlePendingBillsCombined');

    if (bills.isEmpty) return;

    final batch = _db.batch();
    final now = DateTime.now();

    // 1. Calculate merged values
    double totalGameCharge = 0;
    double totalBaseGameCharge = 0;
    double totalOvertimeCharge = 0;
    double totalOrdersTotal = 0;
    double totalDiscountAmount = additionalDiscountAmount;
    double totalCurrentGameDiscountAmount = 0;
    double totalGrandTotal = 0;
    int totalActiveSeconds = 0;

    DateTime? earliestStartTime;
    List<String> tableNames = [];
    List<GameOrder> allOrders = [];
    List<ManualGameCharge> allManualGames = [];
    List<AuditLog> allAuditLogs = [];
    List<GameRound> allRounds = [];

    for (final bill in bills) {
      totalGameCharge += (bill.gameCharge ?? 0);
      totalBaseGameCharge += (bill.baseGameCharge ?? 0);
      totalOvertimeCharge += (bill.overtimeCharge ?? 0);
      totalOrdersTotal += (bill.ordersTotal ?? 0);
      totalDiscountAmount += (bill.discountAmount ?? 0);
      totalCurrentGameDiscountAmount += (bill.currentGameDiscountAmount ?? 0);
      totalGrandTotal +=
          (bill.gameCharge ?? 0) +
          (bill.ordersTotal ?? 0) +
          bill.manualGameCharges.fold<double>(
            0,
            (sum, charge) => sum + charge.calculatedAmount,
          );
      totalActiveSeconds += bill.activeSeconds;

      if (earliestStartTime == null ||
          (bill.startTime != null &&
              bill.startTime!.isBefore(earliestStartTime))) {
        earliestStartTime = bill.startTime;
      }

      if (!tableNames.contains(bill.tableName)) {
        tableNames.add(bill.tableName);
      }

      allOrders.addAll(bill.orders);
      allManualGames.addAll(bill.manualGameCharges);
      allAuditLogs.addAll(bill.auditLogs);
      if (bill.rounds != null) {
        allRounds.addAll(bill.rounds!);
      }

      // Delete the original pending bill
      final originalRef = _db
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(bill.id);
      batch.delete(originalRef);
    }

    final isSplit =
        playerPaymentSplits != null && playerPaymentSplits.isNotEmpty;
    String newPaymentStatus = 'Paid';
    double paidAmount = roundedTotal;
    double remainingAmount = 0.0;
    final consolidatedId = '${DateTime.now().millisecondsSinceEpoch}_combined';

    if (isSplit) {
      double totalCredit = 0.0;
      double totalPaid = 0.0;

      for (var player in playerPaymentSplits.keys) {
        final splits = playerPaymentSplits[player]!;
        for (var entry in splits.entries) {
          if (entry.key == PaymentMethod.credit && entry.value > 0) {
            totalCredit += entry.value;
            final creditRepo = _ref!.read(creditRepositoryProvider);
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: entry.value,
              type: CreditTransactionType.game,
              referenceId: consolidatedId,
              title: 'Consolidated Pending Bill',
              subtitle: 'Tables: ${tableNames.join(", ")}',
              paymentMethod: PaymentMethod.credit,
            );
          } else if (entry.value > 0) {
            totalPaid += entry.value;
          }
        }
      }

      paidAmount = totalPaid;
      remainingAmount = totalCredit;

      if (totalCredit >= roundedTotal - 0.01) {
        newPaymentStatus = 'Outstanding';
      } else if (totalCredit > 0) {
        newPaymentStatus = 'Partially Paid';
      }
    } else if (paymentMethod == PaymentMethod.credit) {
      newPaymentStatus = 'Outstanding';
      paidAmount = 0.0;
      remainingAmount = roundedTotal;

      final creditRepo = _ref!.read(creditRepositoryProvider);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: customerName,
        amount: roundedTotal,
        type: CreditTransactionType.game,
        referenceId: consolidatedId,
        title: 'Consolidated Pending Bill',
        subtitle: 'Tables: ${tableNames.join(", ")}',
        paymentMethod: PaymentMethod.credit,
      );
    }

    // Add consolidation audit log
    final summaryLog = AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_consolidate',
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Consolidated Pending Bills',
      previousValue: '${bills.length} bills',
      newValue: '₹$roundedTotal',
    );
    allAuditLogs.add(summaryLog);

    // Enrich with staff explicitly
    final staffName = currentUserName ?? 'Unknown';
    final staffId = currentUserId ?? 'Unknown';

    final updateMap = {
      'id': consolidatedId,
      'clubId': clubId,
      'tableId': bills.first.tableId, // Just use first for reference
      'tableName': tableNames.join(", "),
      'tableType': bills.first.tableType.name,
      'gameType': bills.first.gameType.name,
      'billingType': bills.first.billingType.name,
      'status': TableStatus.available.name,
      'paymentStatus': newPaymentStatus,
      'paymentMethod': (!isSplit) ? paymentMethod?.name : null,
      'paidBy': paidBy ?? customerName,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'startTime': earliestStartTime != null
          ? Timestamp.fromDate(earliestStartTime)
          : Timestamp.fromDate(now),
      'endTime': Timestamp.fromDate(now),
      'activeSeconds': totalActiveSeconds,
      'players': bills.first.players,

      'gameCharge': totalGameCharge,
      'baseGameCharge': totalBaseGameCharge,
      'overtimeCharge': totalOvertimeCharge,
      'ordersTotal': totalOrdersTotal,
      'discountAmount': totalDiscountAmount,
      'currentGameDiscountAmount': totalCurrentGameDiscountAmount,
      'grandTotal': totalGrandTotal,
      'roundedAmount': roundedTotal,
      'finalAmount': roundedTotal,

      'orders': allOrders.map((o) => o.toMap()).toList(),
      'manualGameCharges': allManualGames.map((m) => m.toMap()).toList(),
      'rounds': allRounds.map((r) => r.toMap()).toList(),
      'auditLogs': allAuditLogs.map((l) => l.toMap()).toList(),

      'createdByUserId': staffId,
      'createdByName': staffName,
      'updatedByUserId': staffId,
      'updatedByName': staffName,
      'date': DateFormat('yyyy-MM-dd').format(now),

      if (isSplit)
        'playerPaymentSplits': playerPaymentSplits.map(
          (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
        ),
    };

    final newGameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(consolidatedId);

    batch.set(newGameRef, updateMap);

    // Global audit log
    final globalLogRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();

    batch.set(globalLogRef, {
      ...summaryLog.toMap(),
      'recordId': consolidatedId,
      'recordType': 'Game',
      'action': 'Consolidated Pending Bills',
    });

    await batch.commit();
  }

  Future<void> settlePendingBill(
    GameSession session, {
    required PaymentMethod? paymentMethod,
    required String? paidBy,
    required Map<String, Map<PaymentMethod, double>>? playerPaymentSplits,
  }) async {
    AppConfig.guardWrite('GamesRepository.settlePendingBill');

    final doc = await _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id)
        .get();

    if (!doc.exists || doc.data()?['status'] != TableStatus.pendingBill.name) {
      throw Exception(
        'This bill is no longer pending or has already been settled.',
      );
    }

    final staff = <String, dynamic>{};
    final now = DateTime.now();

    final isSplit =
        playerPaymentSplits != null && playerPaymentSplits.isNotEmpty;
    final totalAmount =
        session.roundedAmount ??
        session.finalAmount ??
        session.grandTotal ??
        0.0;

    String newPaymentStatus = 'Paid';
    double paidAmount = totalAmount;
    double remainingAmount = 0.0;

    final batch = _db.batch();

    if (isSplit) {
      double totalCredit = 0.0;
      double totalPaid = 0.0;

      for (var player in playerPaymentSplits.keys) {
        final splits = playerPaymentSplits[player]!;
        for (var entry in splits.entries) {
          if (entry.key == PaymentMethod.credit && entry.value > 0) {
            totalCredit += entry.value;
            final creditRepo = _ref!.read(creditRepositoryProvider);
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: entry.value,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Pending Bill',
              paymentMethod: PaymentMethod.credit,
            );
          } else if (entry.value > 0) {
            totalPaid += entry.value;
          }
        }
      }

      paidAmount = totalPaid;
      remainingAmount = totalCredit;

      if (totalCredit >= totalAmount - 0.01) {
        newPaymentStatus = 'Outstanding';
      } else if (totalCredit > 0) {
        newPaymentStatus = 'Partially Paid';
      }
    } else if (paymentMethod == PaymentMethod.credit) {
      newPaymentStatus = 'Outstanding';
      paidAmount = 0.0;
      remainingAmount = totalAmount;

      final customerName = paidBy ?? session.pendingBillCustomerName;

      final creditRepo = _ref!.read(creditRepositoryProvider);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: customerName ?? 'Unknown',
        amount: totalAmount,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Pending Bill',
        paymentMethod: PaymentMethod.credit,
      );
    }

    final updateMap = {
      ...staff,
      'status': TableStatus.available.name,
      'paymentStatus': newPaymentStatus,
      'paymentMethod': (!isSplit) ? paymentMethod?.name : null,
      'paidBy': paidBy,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'endTime': now.toIso8601String(),
      if (isSplit)
        'playerPaymentSplits': playerPaymentSplits.map(
          (k, v) => MapEntry(k, v.map((mk, mv) => MapEntry(mk.name, mv))),
        ),
    };

    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Pending Bill Settled',
      previousValue: 'Pending',
      newValue: '₹$totalAmount',
    );
    final logMap = auditLog.toMap();

    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(session.id);

    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });

    final globalLogRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();

    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Settled Pending Bill',
    });

    await batch.commit();
  }

  Future<void> cancelPendingBill(String gameId, GameSession session) async {
    AppConfig.guardWrite('GamesRepository.cancelPendingBill');

    final staff = <String, dynamic>{};
    final now = DateTime.now();

    final updateMap = {
      ...staff,
      'status': TableStatus.cancelled.name,
      'isCancelled': true,
      'paymentStatus': 'Cancelled',
      'finalAmount': 0.0,
      'grandTotal': 0.0,
      'gameCharge': 0.0,
      'baseGameCharge': 0.0,
      'overtimeCharge': 0.0,
      'ordersTotal': 0.0,
      'manualGamesTotal': 0.0,
      'roundedAmount': 0.0,
    };

    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      editedBy: currentUserName ?? 'Unknown',
      timestamp: now,
      field: 'Pending Bill Cancelled',
      previousValue: 'Pending',
      newValue: 'Cancelled',
    );
    final logMap = auditLog.toMap();

    final batch = _db.batch();

    final gameRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .doc(gameId);

    batch.update(gameRef, {
      ...updateMap,
      'auditLogs': FieldValue.arrayUnion([logMap]),
    });

    if (session.orders.isNotEmpty) {
      for (final order in session.orders) {
        if (order.productId != null) {
          final productRef = _db
              .collection(FirebaseConstants.clubsCollection)
              .doc(clubId)
              .collection('inventory')
              .doc(order.productId);

          batch.update(productRef, {
            'currentStock': FieldValue.increment(order.quantity),
            'totalSold': FieldValue.increment(-order.quantity),
          });
        }
      }
    }

    final globalLogRef = _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection('audit_logs')
        .doc();

    batch.set(globalLogRef, {
      ...logMap,
      'recordId': session.id,
      'recordType': 'Game',
      'action': 'Cancel Pending Bill',
    });

    await batch.commit();
  }

  Stream<List<GameSession>> watchPendingBills() {
    return _db
        .collection(FirebaseConstants.clubsCollection)
        .doc(clubId)
        .collection(FirebaseConstants.gamesCollection)
        .where('status', isEqualTo: TableStatus.pendingBill.name)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => (() {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return GameSession.fromMap(data);
                })(),
              )
              .toList();
          list.sort(
            (a, b) =>
                (b.markedPendingAt ??
                        b.endTime ??
                        b.startTime ??
                        DateTime.now())
                    .compareTo(
                      a.markedPendingAt ??
                          a.endTime ??
                          a.startTime ??
                          DateTime.now(),
                    ),
          );
          return list;
        });
  }

  Future<void> wipeCueZoneData() async {
    print('Starting wipe of CueZone data for club: ');
    final batch = _db.batch();
    final gamesSnap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('games')
        .get();
    for (var doc in gamesSnap.docs) {
      batch.delete(doc.reference);
    }
    final tablesSnap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('tables')
        .get();
    for (var doc in tablesSnap.docs) {
      batch.update(doc.reference, {
        'status': 'available',
        'activeGameId': null,
        'isTimeNotSure': false,
      });
    }
    final playersSnap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('customers')
        .get();
    for (var doc in playersSnap.docs) {
      batch.delete(doc.reference);
    }
    final creditSnap = await _db
        .collection('clubs')
        .doc(clubId)
        .collection('credit_history')
        .get();
    for (var doc in creditSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

Stream<List<OtherGameResource>> watchOtherGames() {
  return const Stream.empty();
}
