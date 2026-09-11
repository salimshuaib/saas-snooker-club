import sys

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("const Text('Staging Club', style: TextStyle", "Text('Staging Club', style: TextStyle")
text = text.replace("const Icon(Icons.menu, color: theme", "Icon(Icons.menu, color: theme")
text = text.replace("const Center(child: Text('No tables configured.', style: TextStyle", "Center(child: Text('No tables configured.', style: TextStyle")

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
