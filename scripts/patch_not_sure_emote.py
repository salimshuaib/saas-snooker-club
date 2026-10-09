import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: game.status == TableStatus.running
                                        ? AppColors.running
                                        : AppColors.paused,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),'''

new_code = '''                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: game.status == TableStatus.running
                                        ? AppColors.running
                                        : AppColors.paused,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Gap(8),
                                GestureDetector(
                                  onTap: () async {
                                    await ref.read(gamesRepositoryProvider).toggleTimeNotSure(
                                      game.id,
                                      !game.isTimeNotSure,
                                    );
                                  },
                                  child: Icon(
                                    game.isTimeNotSure ? Icons.sentiment_dissatisfied : Icons.sentiment_neutral,
                                    size: 18,
                                    color: game.isTimeNotSure ? Colors.red : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),'''

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart for emote')
