import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

class GameValidationUtils {
  /// Normalizes a player name by trimming spaces, removing double spaces, and lowercasing for comparison.
  static String normalizePlayerName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// Validates that a player name only contains letters, numbers, and spaces.
  static String? validatePlayerName(String name) {
    if (name.trim().isEmpty) return 'Player name cannot be empty.';
    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(name)) {
      return 'Player names can only contain letters, numbers, and spaces.';
    }
    return null;
  }

  /// Validates that the frame count is a valid number greater than 0.
  static String? validateFramesCount(String? val) {
    if (val == null || val.trim().isEmpty)
      return 'Please enter a valid number of frames.';
    final count = int.tryParse(val.trim());
    if (count == null || count <= 0) {
      return 'Frame count must be a number greater than 0.';
    }
    return null;
  }

  /// Checks if any player is duplicated within the current setup
  static String? validateDuplicatePlayersWithinGame(
    List<PlayerSelection?> teamA,
    List<PlayerSelection?> teamB,
  ) {
    final allPlayers = [...teamA, ...teamB]
        .where((p) => p != null && p.name.trim().isNotEmpty)
        .cast<PlayerSelection>();
    final seenIds = <String>{};
    final seenNames = <String>{};

    for (final p in allPlayers) {
      if (p.name.trim().toLowerCase().startsWith('default')) continue;

      if (p.id != null) {
        if (seenIds.contains(p.id)) {
          return '${p.name} is added multiple times. A player can only participate once per game.';
        }
        seenIds.add(p.id!);
      } else {
        final norm = normalizePlayerName(p.name);
        if (seenNames.contains(norm)) {
          return '${p.name} is added multiple times. A player can only participate once per game.';
        }
        seenNames.add(norm);
      }
    }
    return null;
  }

  /// Checks if any player is currently active in ANY OTHER table.
  /// Returns a user-friendly error message if a player is already active.
  static Future<String?> checkPlayerActiveElsewhere(
    List<PlayerSelection?> players,
    WidgetRef ref,
    String currentTableId,
  ) async {
    final allPlayers = players
        .where((p) => p != null && p.name.trim().isNotEmpty)
        .cast<PlayerSelection>();
    if (allPlayers.isEmpty) return null;

    final tables = ref.read(resolvedTablesProvider);
    final activeTables = tables.where(
      (t) =>
          t.status != TableStatus.available &&
          t.id != currentTableId &&
          t.activeGameId != null,
    );

    final gamesRepo = ref.read(gamesRepositoryProvider);

    for (final table in activeTables) {
      final game = await gamesRepo.getGameById(table.activeGameId!);
      if (game == null) continue;

      final activeIds = game.playerIds;
      final activeNames =
          game.playerIdentities?.keys.map(normalizePlayerName).toList() ?? [];

      for (final p in allPlayers) {
        if (p.name.trim().toLowerCase().startsWith('default')) continue;

        if (p.id != null) {
          if (activeIds.contains(p.id)) {
            return '⚠️ ${p.name} is currently playing ${game.billingType.displayName} on ${table.name}. They cannot start a new game until that one is finished.';
          }
        } else {
          if (activeNames.contains(normalizePlayerName(p.name))) {
            return '⚠️ ${p.name} is currently playing ${game.billingType.displayName} on ${table.name}. They cannot start a new game until that one is finished.';
          }
        }
      }
    }

    return null;
  }

  /// Checks if a manually typed player name exactly matches an existing player profile in the database.
  static String? validateNameNotExistingInDatabase(
    List<PlayerSelection?> players,
    WidgetRef ref,
  ) {
    final allCustomers = ref.read(allCustomersProvider).value ?? [];
    if (allCustomers.isEmpty) return null;

    final typedPlayers = players
        .where((p) => p != null && p.id == null && p.name.trim().isNotEmpty)
        .map((p) => p!)
        .toList();

    for (final typed in typedPlayers) {
      if (typed.name.trim().toLowerCase().startsWith('default')) continue;
      
      final normTyped = normalizePlayerName(typed.name);
      final exists = allCustomers.any((c) => normalizePlayerName(c.name) == normTyped);
      if (exists) {
        return 'The name "${typed.name}" already exists in the player list. Please select it from the dropdown or change the name to avoid duplicates.';
      }
    }
    return null;
  }
}
