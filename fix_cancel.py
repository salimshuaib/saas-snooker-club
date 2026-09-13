import os

filepath = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """    if (mounted && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar("""
new_code = """    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar("""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
