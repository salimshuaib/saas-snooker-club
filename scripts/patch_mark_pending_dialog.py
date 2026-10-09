import sys

path = 'lib/features/games/presentation/widgets/mark_pending_dialog.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_valid = '''    final hasValidSelections = _selections.every((s) => s != null && s.id != null && s.id!.isNotEmpty) && _selections.isNotEmpty;'''
new_valid = '''    final hasValidSelections = _selections.every((s) => s != null && s.name.trim().isNotEmpty) && _selections.isNotEmpty;'''

old_button = '''        FilledButton(
          onPressed: hasValidSelections ? () {
             final validPlayers = _selections.where((s) => s != null && s.id != null && s.id!.isNotEmpty).cast<PlayerSelection>().toList();
             Navigator.pop(context, validPlayers);
          } : null,'''
new_button = '''        FilledButton(
          onPressed: hasValidSelections ? () {
             final validPlayers = _selections.where((s) => s != null && s.name.trim().isNotEmpty).cast<PlayerSelection>().toList();
             Navigator.pop(context, validPlayers);
          } : null,'''

content = content.replace(old_valid, new_valid)
content = content.replace(old_button, new_button)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched mark_pending_dialog.dart')
