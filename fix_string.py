import re

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r"Text\('Error: \\', style", r"Text('Error: \', style", text)

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
