import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('\\${', '${')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed dollar interpolation in combined settlement screen')
