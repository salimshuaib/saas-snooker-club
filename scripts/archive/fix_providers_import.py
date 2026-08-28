import re

with open('lib/features/games/providers/games_providers.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if 'package:flutter/foundation.dart' not in content:
    content = "import 'package:flutter/foundation.dart';\n" + content
    with open('lib/features/games/providers/games_providers.dart', 'w', encoding='utf-8') as f:
        f.write(content)
