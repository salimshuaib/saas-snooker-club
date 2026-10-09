import sys

path = 'lib/features/games/domain/models/game_models.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add to fromMap
old_code = '''      allowCustomPrice: map['allowCustomPrice'] as bool? ?? false,
    );'''

new_code = '''      allowCustomPrice: map['allowCustomPrice'] as bool? ?? false,
      isTimeNotSure: map['isTimeNotSure'] as bool? ?? false,
    );'''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched fromMap in game_models.dart')
