import sys

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Text('Error: \\$err')", "Text('Error: $err')")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
