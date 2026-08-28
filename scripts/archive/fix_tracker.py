import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I want to delete the whole Race Points Tracker UI
# Search for if (false) ...[  // Disabled: Race games no longer use point tracking
# No, it was removed from the previous script and my git checkout reverted the whole file!
# But the git checkout was for the OLD state of the file before clean_points_tracker.py.
# Let's search for if (game.gameType == GameType.race) ...[
target = '''                if (game.gameType == GameType.race) ...[
                  const Gap(12),
                  Text(
                    'Race Points Tracker (Target: )',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(8),
                  ...game.allPlayers.map((player) {
                    final points = game.playerPoints?[player] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (points > 0) {
                                    _updatePoints(game, player, points - 1);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  points.toString(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _updatePoints(game, player, points + 1);
                                },
                                icon: const Icon(Icons.add_circle),
                                color: AppColors.primary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],'''

content = content.replace(target, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
