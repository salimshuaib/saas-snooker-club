import re

file_path = 'lib/features/games/providers/games_providers.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("data: (tables) => sortTables(tables.isEmpty ? TablesConfig.defaultTables : tables),", "data: (tables) => sortTables(tables),")
content = content.replace("loading: () => sortTables(TablesConfig.defaultTables),", "loading: () => async.value != null ? sortTables(async.value!) : [],")
content = content.replace("error: (_, __) => sortTables(TablesConfig.defaultTables),", "error: (_, __) => async.value != null ? sortTables(async.value!) : [],")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
