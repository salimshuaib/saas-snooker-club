import re

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Scaffold background
text = re.sub(r"backgroundColor: AppColors\.previewPrimaryDark,", r"backgroundColor: theme.scaffoldBackgroundColor,", text)
# AppBar background
text = re.sub(r"appBar: AppBar\(\s*backgroundColor: AppColors\.previewPrimaryDark,", r"appBar: AppBar(\n          backgroundColor: theme.scaffoldBackgroundColor,", text)

# Text colors
text = re.sub(r"color: AppColors\.previewLightBackground", r"color: theme.colorScheme.onBackground", text)

# Icon colors
text = re.sub(r"color: AppColors\.previewLightBackground", r"color: theme.colorScheme.onBackground", text)

# TabBar colors
text = re.sub(r"indicatorColor: AppColors\.previewSecondary,", r"indicatorColor: theme.colorScheme.primary,", text)
text = re.sub(r"labelColor: AppColors\.previewSecondary,", r"labelColor: theme.colorScheme.primary,", text)
text = re.sub(r"unselectedLabelColor: theme\.colorScheme\.onBackground\.withValues\(alpha: 0\.5\),", r"unselectedLabelColor: theme.colorScheme.onSurfaceVariant,", text)
text = re.sub(r"dividerColor: AppColors\.previewLine,", r"dividerColor: theme.colorScheme.outlineVariant,", text)


with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
