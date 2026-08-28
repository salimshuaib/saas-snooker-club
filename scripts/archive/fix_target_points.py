import os

def fix_target_points():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove target points block
    old_target_block = """                if (_gameType == GameType.race) ...[
                  Text('Target Points (Optional)', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  AppTextField(
                    hint: 'e.g. 50',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _targetPoints = int.tryParse(val);
                    },
                  ),
                  const Gap(24),
                ],"""
    
    content = content.replace(old_target_block, "")
    
    # Also in _startGame:
    # `targetPoints: _gameType == GameType.race ? _targetPoints : null,` -> `targetPoints: null,`
    content = content.replace("targetPoints: _gameType == GameType.race ? _targetPoints : null,", "targetPoints: null,")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_target_points()
