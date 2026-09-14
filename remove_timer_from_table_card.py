import re

filepath = 'lib/features/games/presentation/widgets/table_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

pattern = re.compile(r'// Timer \+ Bill \(only when running/paused\)\s*activeGameAsync\.when\(\s*loading: \(\) => const SizedBox\.shrink\(\),\s*error: \(\_, \_\_\) => const SizedBox\.shrink\(\),\s*data: \(game\) \{\s*if \(game == null\) return const SizedBox\.shrink\(\);\s*return \_ActiveGameInfo\(game: game\);\s*\},\s*\),', re.MULTILINE)

text = pattern.sub('', text)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
