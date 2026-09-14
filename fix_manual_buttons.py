import re

def remove_manual_inkwell(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()

    # Regex for table_card and game_activity_card
    pattern_inkwell = re.compile(r'\s*const Gap\(4\),\s*InkWell\(\s*onTap: \(\) \{[\s\S]*?Text\(\'Manual\',[\s\S]*?\]\,\s*\)\n\s*\),\s*\),', re.MULTILINE)
    text = pattern_inkwell.sub('', text)
    
    # Also another variant with SizedBox(width: 8)
    pattern_inkwell_2 = re.compile(r'\s*const SizedBox\(width: 8\),\s*InkWell\(\s*onTap: \(\) \{[\s\S]*?Text\(\'Manual\',[\s\S]*?\]\,\s*\)\,\s*\)\,\s*\),', re.MULTILINE)
    text = pattern_inkwell_2.sub('', text)

    # Regex for active_game_card (FilledButton)
    pattern_button = re.compile(r'\s*const Gap\(12\),\s*FilledButton\.tonalIcon\(\s*style:[\s\S]*?label: const Text\(\'Manual Entry\'[\s\S]*?\}\,\s*\),', re.MULTILINE)
    text = pattern_button.sub('', text)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)

files = [
    'lib/features/games/presentation/widgets/table_card.dart',
    'lib/features/games/presentation/widgets/game_activity_card.dart',
    'lib/features/games/presentation/widgets/active_game_card.dart',
]

for f in files:
    remove_manual_inkwell(f)

print("SUCCESS")
