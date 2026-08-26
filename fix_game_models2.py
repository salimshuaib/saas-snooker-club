import os

def fix_game_models():
    path = 'lib/features/games/domain/models/game_models.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace('this.playerIds = const [],', 'this.playerIds = const [],\n    this.playerIdentities,')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_game_models()
