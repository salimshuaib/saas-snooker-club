import sys

path = 'lib/features/games/presentation/widgets/game_activity_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                            GestureDetector(
                              onTap: () async {
                                await ref.read(gamesRepositoryProvider).toggleTimeNotSure(
                                  table.id,
                                  !table.isTimeNotSure,
                                );
                              },
                              child: Icon(
                                table.isTimeNotSure ? Icons.sentiment_dissatisfied : Icons.sentiment_neutral,
                                size: 18,
                                color: table.isTimeNotSure ? Colors.red : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),'''

new_code = '''                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                await ref.read(gamesRepositoryProvider).toggleTimeNotSure(
                                  table.id,
                                  !table.isTimeNotSure,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                child: Icon(
                                  table.isTimeNotSure ? Icons.sentiment_dissatisfied : Icons.sentiment_neutral,
                                  size: 18,
                                  color: table.isTimeNotSure ? Colors.red : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ),'''

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched game_activity_card.dart for hit testing')
