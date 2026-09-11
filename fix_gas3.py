import re

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final tablesAsync = ref.watch(resolvedTablesProvider);", "final theme = Theme.of(context);\n    final tablesAsync = ref.watch(resolvedTablesProvider);")

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
