import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                                const Gap(8),
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
                                ),'''

new_code = '''                                const Gap(8),
                                GestureDetector(
                                  onTap: () async {
                                    await ref.read(gamesRepositoryProvider).toggleTimeNotSure(
                                      widget.table.id,
                                      !widget.table.isTimeNotSure,
                                    );
                                  },
                                  child: Icon(
                                    widget.table.isTimeNotSure ? Icons.sentiment_dissatisfied : Icons.sentiment_neutral,
                                    size: 18,
                                    color: widget.table.isTimeNotSure ? Colors.red : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),'''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart')
