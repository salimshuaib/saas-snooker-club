import re

with open('lib/features/games/presentation/screens/table_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add gameType chip
info_chip_old = "_InfoChip(icon: Icons.sports_esports,\n                        label: game.tableType.displayName),"
info_chip_new = "_InfoChip(icon: Icons.sports_esports,\n                        label: game.tableType.displayName),\n                    _InfoChip(icon: Icons.category,\n                        label: game.gameType.displayName),"
content = content.replace(info_chip_old, info_chip_new)

# Add RaceScoreboard
race_scoreboard = '''
                if (game.gameType == GameType.race) ...[
                  const Gap(12),
                  Text('Race Points Tracker (Target: )', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Gap(8),
                  ...game.allPlayers.map((player) {
                    final points = game.playerPoints?[player] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(player, style: theme.textTheme.bodyMedium)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              final newPoints = Map<String, int>.from(game.playerPoints ?? {});
                              newPoints[player] = (newPoints[player] ?? 0) - 1;
                              ref.read(gameSessionControllerProvider.notifier).updateGame(game.copyWith(playerPoints: newPoints));
                            },
                          ),
                          Text('', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              final newPoints = Map<String, int>.from(game.playerPoints ?? {});
                              newPoints[player] = (newPoints[player] ?? 0) + 1;
                              ref.read(gameSessionControllerProvider.notifier).updateGame(game.copyWith(playerPoints: newPoints));
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                const Gap(12),
'''

completed_rounds_pattern = "                // Completed Rounds"
content = content.replace(completed_rounds_pattern, race_scoreboard + completed_rounds_pattern)

with open('lib/features/games/presentation/screens/table_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
