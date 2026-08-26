import re

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Restore AppTextField
content = content.replace("          TextField(\n            hint: 'e.g., 100',", "          AppTextField(\n            hint: 'e.g., 100',")

# Add import
import_stmt = "import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';\n"
if "app_text_field.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)
