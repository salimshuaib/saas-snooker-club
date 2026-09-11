import sys

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("theme.colorScheme.onBackground", "theme.colorScheme.onSurface")

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
