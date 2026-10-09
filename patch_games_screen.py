import re

file_path = 'lib/features/games/presentation/screens/games_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'@override\s*void initState\(\)\s*\{\s*super\.initState\(\);\s*WidgetsBinding\.instance\.addPostFrameCallback\(\(\_\)\s*\{\s*// Seed default tables if first launch\s*ref\.read\(gamesRepositoryProvider\)\.seedTablesIfEmpty\(\);\s*\}\);\s*\}',
    '',
    content,
    flags=re.MULTILINE
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
