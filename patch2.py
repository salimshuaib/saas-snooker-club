import re

with open('lib/features/games/data/games_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 2: Remove duplicated auditLogs from updateMap in endGame
pattern = re.compile(r"'playerIdentities': session\.playerIdentities,\s*'auditLogs': session\.auditLogs\.map\(\(a\) => a\.toMap\(\)\)\.toList\(\),\s*};")
replacement = r"'playerIdentities': session.playerIdentities,\n      };"

content = pattern.sub(replacement, content)

with open('lib/features/games/data/games_repository.dart', 'w', encoding='utf-8') as f:
    f.write(content)
