import sys

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("const Padding(\n            padding: EdgeInsets.symmetric(horizontal: 16.0),\n            child: Row(", "Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 16.0),\n            child: Row(")
text = text.replace("children: [\n                Text('Admin'", "children: [\n                Text('Admin'")
text = text.replace("SizedBox(width: 8)", "const SizedBox(width: 8)")

with open('lib/features/games/presentation/screens/game_activity_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
