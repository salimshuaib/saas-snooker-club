import sys

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('AppColors.previewSecondary', 'theme.colorScheme.primary')
text = text.replace('AppColors.previewPrimaryDark', 'theme.colorScheme.surface')
text = text.replace('AppColors.previewLightBackground.withValues(alpha: 0.5)', 'theme.colorScheme.onSurfaceVariant')
text = text.replace('AppColors.previewLightBackground', 'theme.colorScheme.onBackground')

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
