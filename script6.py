import sys

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_pop = '''      if (mounted) {
        Navigator.pop(context, gameSession);
        didPop = true;
      }'''

new_pop = '''      if (mounted) {
        if (widget.isInline) {
           widget.onCancel?.call();
        } else {
           Navigator.pop(context, gameSession);
           didPop = true;
        }
      }'''
text = text.replace(old_pop, new_pop)

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
