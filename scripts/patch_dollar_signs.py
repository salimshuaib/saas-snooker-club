import sys

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace all \$ with $ where appropriate (meaning everywhere, since we want them to interpolate)
content = content.replace(r'\${', '${')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched \$')
