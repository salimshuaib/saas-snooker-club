import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/features/games/data/games_repository.dart';
import 'package:snooker_club/features/games/domain/config/tables_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Repository Provider
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  final clubId = ref.watch(clubIdProvider);
  return GamesRepository(ref: ref, clubId: clubId);
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Selected Date
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

String dateToString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Tables â€” Real-time stream
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Tables stream with local fallback.
/// If Firestore is unavailable (permission denied, offline, etc.),
/// it returns the default hardcoded tables so the UI always works.
final tablesProvider = StreamProvider<List<TableModel>>((ref) {
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchTables().handleError((_) {});
});

/// Resolved tables: Firestore data if available, otherwise central default tables.
final resolvedTablesProvider = Provider<List<TableModel>>((ref) {
  final async = ref.watch(tablesProvider);
  return async.when(
    data: (tables) => tables.isEmpty ? TablesConfig.defaultTables : tables,
    loading: () => TablesConfig.defaultTables,
    error: (_, __) => TablesConfig.defaultTables,
  );
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Active Game â€” per table
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final activeGameProvider = StreamProvider.autoDispose.family<GameSession?, String>((
  ref,
  tableId,
) {
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchActiveGame(tableId);
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Games History â€” per table and date
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final tableGamesProvider =
    StreamProvider.autoDispose.family<List<GameSession>, ({String tableId, String date})>((
      ref,
      args,
    ) {
      final repo = ref.watch(gamesRepositoryProvider);
      if (repo.clubId == null) return const Stream.empty();
      return repo.watchGamesByTableAndDate(args.tableId, args.date);
    });

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Game Session Controller
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class GameSessionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  GamesRepository get _repo => ref.read(gamesRepositoryProvider);

  Future<void> startGame(GameSession session) async {
    state = const AsyncValue.loading();
    try {
      await _repo.startGame(session);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> updatePlayerPoints(
    String gameId,
    Map<String, int> playerPoints,
  ) async {
    try {
      await _repo.updatePlayerPoints(gameId, playerPoints);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> pauseGame(String gameId, String tableId) async {
    try {
      await _repo.pauseGame(gameId, tableId, DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> resumeGame(String gameId, String tableId) async {
    try {
      await _repo.resumeGame(gameId, tableId, DateTime.now());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> cancelGame(String gameId, String tableId, List<GameOrder> orders) async {
    try {
      await _repo.cancelGame(gameId, tableId, orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> updateOrders(String gameId, List<GameOrder> orders) async {
    try {
      await _repo.updateOrders(gameId, orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> updateGameRounds(
    String gameId,
    List<GameRound> rounds,
    int totalFrames,
    int framesPlayed,
  ) async {
    try {
      await _repo.updateGameRounds(gameId, rounds, totalFrames, framesPlayed);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> markBilling(String gameId, String tableId) async {
    try {
      await _repo.markBilling(gameId, tableId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> endGame(GameSession session) async {
    state = const AsyncValue.loading();
    try {
      await _repo.endGame(session);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
        rethrow;
    }
  }

  Future<void> deleteGames(List<GameSession> sessions) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteGameSessions(sessions);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final gameSessionControllerProvider =
    NotifierProvider<GameSessionController, AsyncValue<void>>(
      GameSessionController.new,
    );

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Timer Provider â€” local, per active game
// Calculates elapsed time from startTime + pauses.
// Does NOT write to Firestore every second.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final gameTimerProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  gameId,
) async* {
  // Yield every second
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    // We rely on the activeGameProvider to supply the session
    // The controller that calls this will pass the game session
    yield DateTime.now().millisecondsSinceEpoch;
  }
});

// Helper: generate a new unique game ID
String generateGameId(String clubId) {
  return FirebaseFirestore.instance.collection(FirebaseConstants.clubsCollection).doc(clubId).collection('games').doc().id;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Dashboard Stats Providers
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provider for calculating today's Games revenue (excluding credit payments)
final todaysGamesRevenueStreamProvider = StreamProvider<double>((ref) {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllGamesByDate(dateStr).map((
    games,
  ) {
    return games
        .where((g) => g.status == TableStatus.available)
        .fold(0.0, (sum, g) => sum + (g.grandTotal ?? 0.0));
  });
});

final selectedDateGamesRevenueStreamProvider = StreamProvider<double>((ref) {
  final now = ref.watch(revenueDetailsDateProvider);
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllGamesByDate(dateStr).map((
    games,
  ) {
    return games
        .where((g) => g.status == TableStatus.available)
        .fold(0.0, (sum, g) => sum + (g.grandTotal ?? 0.0));
  });
});

final todaysCompletedPaidGamesProvider = StreamProvider<List<GameSession>>((
  ref,
) {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllGamesByDate(dateStr).map((
    games,
  ) {
    return games.where((g) => g.status == TableStatus.available).toList();
  });
});

final selectedDateCompletedPaidGamesProvider = StreamProvider<List<GameSession>>((
  ref,
) {
  final now = ref.watch(revenueDetailsDateProvider);
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllGamesByDate(dateStr).map((
    games,
  ) {
    return games.where((g) => g.status == TableStatus.available).toList();
  });
});

/// Provider for calculating today's total combined business revenue (Games + Quick Sales)
final todaysRevenueProvider = Provider<AsyncValue<double>>((ref) {
  final gamesRevAsync = ref.watch(todaysGamesRevenueStreamProvider);
  final quickSalesRev = ref.watch(todaysQuickSalesRevenueProvider);

  return gamesRevAsync.whenData((gamesRev) => gamesRev + quickSalesRev);
});

/// Provider for counting running tables
final runningTablesCountProvider = Provider<int>((ref) {
  final tables = ref.watch(resolvedTablesProvider);
  return tables
      .where(
        (t) =>
            t.status == TableStatus.running || t.status == TableStatus.paused,
      )
      .length;
});

/// Provider for counting available tables
final availableTablesCountProvider = Provider<int>((ref) {
  final tables = ref.watch(resolvedTablesProvider);
  return tables.where((t) => t.status == TableStatus.available).length;
});

/// Provider for calculating pending credits (games closed with credit payment method)
final pendingCreditsProvider = StreamProvider<double>((ref) {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final repo = ref.watch(gamesRepositoryProvider);
  if (repo.clubId == null) return const Stream.empty();
  return repo.watchAllGamesByDate(dateStr).map((
    games,
  ) {
    return games
        .where(
          (g) =>
              g.status == TableStatus.available &&
              g.paymentMethod == PaymentMethod.credit,
        )
        .fold(0.0, (sum, g) => sum + (g.grandTotal ?? 0.0));
  });
});


final resolvedOtherGamesProvider = Provider<List<OtherGameResource>>((ref) {
  return [];
});


