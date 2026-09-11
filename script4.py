import re

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the broken list block
old_list = '''          widget.isInline ? ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
          ] : Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: ['''

new_list = '''          Flexible(
            child: ListView(
              shrinkWrap: widget.isInline,
              physics: widget.isInline ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.all(20),
              children: ['''
text = text.replace(old_list, new_list)

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
