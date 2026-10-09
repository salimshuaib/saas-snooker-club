import sys

# 1. Remove from active_game_card.dart
path_active = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path_active, 'r', encoding='utf-8') as f:
    content_active = f.read()

bad_emote = '''                                const Gap(8),
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

content_active = content_active.replace(bad_emote, '')
with open(path_active, 'w', encoding='utf-8') as f:
    f.write(content_active)


# 2. Add to game_activity_card.dart
path_activity = 'lib/features/games/presentation/widgets/game_activity_card.dart'
with open(path_activity, 'r', encoding='utf-8') as f:
    content_activity = f.read()

old_text = '''                          Text(
                            isAvailable
                                ? 'AVAILABLE'
                                : (isRunning ? 'RUNNING' : 'PAUSED'),
                            style: TextStyle(
                              color: isAvailable
                                  ? AppColors.available
                                  : (isRunning
                                      ? AppColors.success
                                      : AppColors.paused),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),'''

new_text = '''                          Text(
                            isAvailable
                                ? 'AVAILABLE'
                                : (isRunning ? 'RUNNING' : 'PAUSED'),
                            style: TextStyle(
                              color: isAvailable
                                  ? AppColors.available
                                  : (isRunning
                                      ? AppColors.success
                                      : AppColors.paused),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isAvailable && gameAsync.value != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
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
                            ),
                          ],'''

content_activity = content_activity.replace(old_text, new_text)

if "import 'package:snooker_club/features/games/providers/games_providers.dart';" not in content_activity:
    content_activity = "import 'package:snooker_club/features/games/providers/games_providers.dart';\n" + content_activity

with open(path_activity, 'w', encoding='utf-8') as f:
    f.write(content_activity)

print('Patched successfully')
