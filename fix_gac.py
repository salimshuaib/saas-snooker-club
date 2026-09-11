import sys

with open('lib/features/games/presentation/widgets/game_activity_card.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('AppColors.previewPrimaryDark', 'theme.colorScheme.onPrimary')
text = text.replace('AppColors.previewPrimary', 'theme.colorScheme.surface')
text = text.replace('AppColors.previewLine', 'theme.colorScheme.outlineVariant')
text = text.replace('AppColors.previewLightBackground.withOpacity(0.5)', 'theme.colorScheme.onSurfaceVariant')
text = text.replace('AppColors.previewLightBackground', 'theme.colorScheme.onSurface')
text = text.replace('AppColors.previewSecondary', 'theme.colorScheme.primary')

# In game_activity_card.dart, there's const TextStyle(...) which will throw an error if we use 	heme.colorScheme.onSurface directly.
# We need to remove the const keyword.
text = text.replace('const TextStyle(\n                          color: theme.colorScheme.onSurface,', 'TextStyle(\n                          color: theme.colorScheme.onSurface,')

with open('lib/features/games/presentation/widgets/game_activity_card.dart', 'w', encoding='utf-8') as f:
    f.write(text)
