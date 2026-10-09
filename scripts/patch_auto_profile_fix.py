import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''          final newProfile = PlayerProfile(
            id: newId,
            name: p.name.trim(),
            createdAt: now,
            isActive: true,
          );
          await creditRepo.createPlayerProfile(newProfile);'''

new_code = '''          final newProfile = PlayerProfile(
            id: newId,
            name: p.name.trim(),
            lastTransactionDate: now,
          );
          await creditRepo.savePlayerProfile(newProfile);'''

content = content.replace(old_code, new_code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart again')
