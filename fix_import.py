import os

def fix_import():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace(
        "import 'package:snooker_club/features/games/providers/games_providers.dart';", 
        "import 'package:snooker_club/features/games/providers/games_providers.dart';\nimport 'package:snooker_club/features/credit/providers/credit_providers.dart';"
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_import()
