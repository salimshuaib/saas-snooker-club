import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('const Icon(Icons.pending_actions, size: 16)', 'const Icon(Icons.shopping_basket, size: 16)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart')
